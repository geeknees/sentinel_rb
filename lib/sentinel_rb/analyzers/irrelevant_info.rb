# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Analyzers
    # A1: Irrelevant Information Detector
    # Detects prompts containing irrelevant or noisy information that could
    # degrade LLM performance or confuse the model.
    class IrrelevantInfo < Base
      ANALYZER_ID = "A1"

      def call
        findings = []

        # Get relevance analysis from LLM
        analysis = @client.analyze_content(@prompt)
        relevance_score = analysis[:relevance_score]
        threshold = @config.relevance_threshold

        # Check if relevance score is below threshold
        if threshold_exceeded?(relevance_score, threshold, higher_is_better: true)
          findings << create_finding(
            id: ANALYZER_ID,
            level: :warn,
            message: "Prompt contains potentially irrelevant information (relevance score: #{relevance_score.round(3)} < threshold: #{threshold})",
            details: {
              relevance_score: relevance_score,
              threshold: threshold,
              raw_response: analysis[:raw_response],
              suggestions: generate_suggestions(relevance_score)
            }
          )
        end

        # Additional heuristic checks
        findings.concat(check_length_ratio)
        findings.concat(check_repetitive_content)
        findings.concat(check_off_topic_markers)

        findings
      end

      private

      # Check if prompt has unusual length patterns that might indicate noise
      def check_length_ratio
        return [] if @prompt.length < 100

        sentences = @prompt.split(/[.!?]+/).reject(&:empty?)
        return [] if sentences.length < 3

        # Calculate variance in sentence lengths
        lengths = sentences.map(&:length)
        avg_length = lengths.sum.to_f / lengths.length
        variance = lengths.map { |len| (len - avg_length) ** 2 }.sum / lengths.length
        std_dev = Math.sqrt(variance)

        # Flag if there's high variance (suggesting mix of very long and short sentences)
        coefficient_of_variation = std_dev / avg_length

        if coefficient_of_variation > 1.5
          [create_finding(
            id: ANALYZER_ID,
            level: :info,
            message: "Prompt has highly variable sentence lengths, which may indicate mixed content types",
            details: {
              coefficient_of_variation: coefficient_of_variation.round(3),
              avg_sentence_length: avg_length.round(1),
              sentence_count: sentences.length
            }
          )]
        else
          []
        end
      end

      # Check for repetitive content that might be noise
      def check_repetitive_content
        words = @prompt.downcase.scan(/\w+/)
        return [] if words.length < 20

        # Count word frequencies
        word_counts = Hash.new(0)
        words.each { |word| word_counts[word] += 1 }

        # Find words that appear unusually often
        avg_frequency = words.length.to_f / word_counts.keys.length
        repetitive_words = word_counts.select { |word, count| 
          count > avg_frequency * 3 && word.length > 3
        }

        if repetitive_words.any?
          [create_finding(
            id: ANALYZER_ID,
            level: :info,
            message: "Prompt contains repetitive words that may indicate redundant content",
            details: {
              repetitive_words: repetitive_words.keys.take(5),
              repetition_ratio: repetitive_words.values.sum.to_f / words.length
            }
          )]
        else
          []
        end
      end

      # Check for common markers of off-topic content
      def check_off_topic_markers
        findings = []
        
        # Common patterns that might indicate irrelevant content
        noise_patterns = [
          /\b(disclaimer|legal notice|copyright|terms of service)\b/i,
          /\b(marketing|advertisement|promotional|sponsor)\b/i,
          /\b(lorem ipsum|placeholder|example text|sample content)\b/i,
          /\b(todo|fixme|note to self|reminder)\b/i
        ]

        noise_patterns.each_with_index do |pattern, index|
          if @prompt.match?(pattern)
            findings << create_finding(
              id: ANALYZER_ID,
              level: :info,
              message: "Prompt contains potential noise markers (pattern #{index + 1})",
              details: {
                pattern_matched: pattern.source,
                matches: @prompt.scan(pattern).flatten.uniq.take(3)
              }
            )
          end
        end

        findings
      end

      # Generate helpful suggestions based on relevance score
      def generate_suggestions(score)
        suggestions = []

        if score < 0.3
          suggestions << "Consider rewriting the prompt to focus on a single, clear objective"
          suggestions << "Remove any background information not directly relevant to the task"
        elsif score < 0.5
          suggestions << "Try to make the main task or question more prominent"
          suggestions << "Consider breaking complex prompts into simpler, focused parts"
        else
          suggestions << "Consider minor refinements to improve clarity and focus"
        end

        suggestions << "Review the prompt for any repetitive or redundant information"
        suggestions
      end
    end
  end
end
