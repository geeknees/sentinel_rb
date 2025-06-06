# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Client
    # Enhanced mock client with improved detection for testing
    class Mock < Base
      def initialize(config)
        super
        @relevance_scores = config["mock_scores"] || {}
      end

      def similarity(text1, text2)
        # Enhanced similarity calculation with Japanese support
        words1 = extract_words(text1)
        words2 = extract_words(text2)
        
        return 0.0 if words1.empty? || words2.empty?
        
        intersection = (words1 & words2).length
        union = (words1 | words2).length
        
        intersection.to_f / union
      end

      def analyze_content(prompt)
        # Enhanced mock analysis with better pattern detection
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

      def extract_words(text)
        # Extract words supporting both English and Japanese
        text.downcase.scan(/[\w\p{Hiragana}\p{Katakana}\p{Han}]+/)
      end

      def calculate_mock_relevance(prompt)
        # Enhanced scoring with more aggressive detection
        score = 0.75 # Start with medium-high base score
        
        # More comprehensive marketing language detection
        marketing_patterns = [
          # English marketing terms
          /\b(sale|discount|offer|buy now|limited time|special|exclusive|amazing|incredible)\b/i,
          /\b(deal|bargain|cheap|free|bonus|gift|prize|winner|congratulations)\b/i,
          /\b(urgent|hurry|act now|don't miss|last chance|final call)\b/i,
          # Japanese marketing terms  
          /\b(セール|割引|特別|お得|今すぐ|限定|無料|プレゼント|キャンペーン)\b/i,
          /\b(急げ|お急ぎ|見逃すな|最後|チャンス|特価|激安)\b/i,
          # Punctuation patterns
          /[!]{2,}/, # Multiple exclamation marks
          /[？]{2,}/, # Multiple question marks
          /[★☆]{2,}/, # Multiple stars
        ]
        
        marketing_count = 0
        marketing_patterns.each do |pattern|
          matches = prompt.scan(pattern).length
          if matches > 0
            marketing_count += matches
            penalty = matches * 0.15 # More aggressive penalty
            score -= penalty
            puts "Debug: Marketing pattern found: #{pattern.source} (#{matches} matches, -#{penalty})" if ENV['DEBUG']
          end
        end
        
        # Enhanced noise marker detection
        noise_patterns = [
          /\b(todo|fixme|disclaimer|note|warning|注意|注記)\b/i,
          /\b(legal notice|copyright|terms|conditions|利用規約|法的免責|免責事項)\b/i,
          /\b(placeholder|example|sample|template|テンプレート|例)\b/i,
          /※.*/, # Japanese note markers
          /\[.*\]/, # Bracketed content (often metadata)
          /\{.*\}/, # Braced content (often placeholders)
        ]
        
        noise_count = 0
        noise_patterns.each do |pattern|
          matches = prompt.scan(pattern).length
          if matches > 0
            noise_count += matches
            penalty = matches * 0.2 # Significant penalty for noise
            score -= penalty
            puts "Debug: Noise pattern found: #{pattern.source} (#{matches} matches, -#{penalty})" if ENV['DEBUG']
          end
        end
        
        # Enhanced repetition detection
        words = extract_words(prompt)
        if words.length > 5
          word_counts = Hash.new(0)
          words.each { |word| word_counts[word] += 1 }
          
          # More aggressive repetition detection
          repetitive_words = word_counts.select { |word, count| 
            count >= 2 && word.length > 1 # Lower threshold, shorter words included
          }
          
          if repetitive_words.any?
            # Calculate repetition severity
            total_repetitions = repetitive_words.values.sum - repetitive_words.length
            repetition_ratio = total_repetitions.to_f / words.length
            penalty = repetition_ratio * 0.5 # Up to 50% penalty for heavy repetition
            score -= penalty
            puts "Debug: Repetitive words found: #{repetitive_words.keys} (ratio: #{repetition_ratio.round(3)}, -#{penalty.round(3)})" if ENV['DEBUG']
          end
        end
        
        # Detect excessive capitalization (shouting)
        caps_ratio = prompt.scan(/[A-Z]/).length.to_f / prompt.length
        if caps_ratio > 0.3 # More than 30% caps
          caps_penalty = (caps_ratio - 0.3) * 0.4
          score -= caps_penalty
          puts "Debug: Excessive capitalization found: #{(caps_ratio * 100).round(1)}% (-#{caps_penalty.round(3)})" if ENV['DEBUG']
        end
        
        # Detect very short sentences (fragmented content)
        sentences = prompt.split(/[.!?。！？]/).reject(&:empty?)
        if sentences.length > 3
          short_sentences = sentences.select { |s| s.strip.split.length < 3 }
          if short_sentences.length > sentences.length * 0.4 # More than 40% short sentences
            fragmentation_penalty = 0.15
            score -= fragmentation_penalty
            puts "Debug: Fragmented content detected: #{short_sentences.length}/#{sentences.length} short sentences (-#{fragmentation_penalty})" if ENV['DEBUG']
          end
        end
        
        # Apply cumulative penalty for multiple issues
        total_issues = marketing_count + noise_count
        if total_issues >= 5
          cumulative_penalty = (total_issues - 4) * 0.05 # Additional penalty for many issues
          score -= cumulative_penalty
          puts "Debug: Cumulative penalty for #{total_issues} issues: -#{cumulative_penalty}" if ENV['DEBUG']
        end
        
        # Ensure score is within bounds
        final_score = [[score, 0.0].max, 1.0].min
        puts "Debug: Final relevance score: #{final_score} (marketing: #{marketing_count}, noise: #{noise_count})" if ENV['DEBUG']
        final_score
      end
    end
  end
end
