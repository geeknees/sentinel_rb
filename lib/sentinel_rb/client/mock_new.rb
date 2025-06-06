# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Client
    # Mock client for testing without API keys
    class Mock < Base
      def initialize(config)
        super
        @relevance_scores = config["mock_scores"] || {}
      end

      def similarity(text1, text2)
        # Simple mock similarity based on word overlap
        words1 = text1.downcase.scan(/\w+/)
        words2 = text2.downcase.scan(/\w+/)

        return 0.0 if words1.empty? || words2.empty?

        intersection = (words1 & words2).length
        union = (words1 | words2).length

        intersection.to_f / union
      end

      def analyze_content(prompt)
        # Mock analysis based on content characteristics
        score = calculate_mock_relevance(prompt)

        {
          relevance_score: score,
          raw_response: score.to_s
        }
      end

      def fact_check(_statement)
        # Mock fact-checking - always returns neutral result
        {
          accurate: true,
          confidence: 0.8,
          reason: "Mock fact-check: No real verification performed"
        }
      end

      private

      def calculate_mock_relevance(prompt)
        # Mock scoring based on content patterns
        score = 0.8 # Start with high base score

        # Reduce score for marketing language
        marketing_patterns = [
          /\b(sale|discount|offer|buy now|limited time|special|セール|割引|特別|今すぐ|購入|限定|お得)\b/i,
          /[!]{2,}/, # Multiple exclamation marks
          /\b(amazing|exclusive|満足度|オファー|お電話)\b/i
        ]

        marketing_count = 0
        marketing_patterns.each do |pattern|
          matches = prompt.scan(pattern)
          if matches.any?
            marketing_count += matches.length
            puts "Debug: Marketing pattern found #{matches.length} times: #{pattern.source}" if ENV['DEBUG']
          end
        end

        # More aggressive penalty for multiple marketing terms
        if marketing_count > 0
          marketing_penalty = [marketing_count * 0.15, 0.6].min
          score -= marketing_penalty
          puts "Debug: Marketing penalty: #{marketing_penalty} (count: #{marketing_count})" if ENV['DEBUG']
        end

        # Reduce score for noise markers
        noise_patterns = [
          /\b(todo|fixme|disclaimer|法的免責|免責事項)\b/i,
          /\b(legal notice|copyright|※)\b/i
        ]

        noise_patterns.each do |pattern|
          if prompt.match?(pattern)
            score -= 0.25
            puts "Debug: Noise pattern found: #{pattern.source}" if ENV['DEBUG']
          end
        end

        # Check for excessive repetition of words (supports Japanese)
        words = prompt.scan(/[\w\p{Hiragana}\p{Katakana}\p{Han}]+/)
        if words.length > 5
          word_counts = Hash.new(0)
          words.each { |word| word_counts[word] += 1 }

          # Find words that appear more than 2 times and are longer than 1 character
          repetitive_words = word_counts.select { |word, count| count >= 3 && word.length > 1 }

          if repetitive_words.any?
            repetition_penalty = repetitive_words.map { |word, count| (count - 2) * 0.1 }.sum
            score -= [repetition_penalty, 0.4].min
            puts "Debug: Repetitive words found: #{repetitive_words}" if ENV['DEBUG']
          end
        end

        # Ensure score is within bounds
        final_score = [[score, 0.0].max, 1.0].min
        puts "Debug: Final relevance score: #{final_score}" if ENV['DEBUG']
        final_score
      end
    end
  end
end
