# frozen_string_literal: true

require "openai"
require_relative "base"

module SentinelRb
  module Client
    # OpenAI client implementation for LLM interactions
    class OpenAI < Base
      def initialize(config)
        super
        @client = ::OpenAI::Client.new(
          access_token: ENV[config.api_key_env] || ENV["OPENAI_API_KEY"],
          log_errors: config["log_level"] == "debug"
        )
        @model = config.model
      end

      # Calculate semantic similarity between two texts using embeddings
      def similarity(text1, text2)
        embedding1 = get_embedding(text1)
        embedding2 = get_embedding(text2)

        cosine_similarity(embedding1, embedding2)
      rescue StandardError => e
        # Fallback to basic text comparison if embeddings fail
        puts "Warning: Embeddings failed, using fallback similarity: #{e.message}" if @config["log_level"] == "debug"
        fallback_similarity(text1, text2)
      end

      # Analyze content for relevance using LLM
      def analyze_content(prompt)
        response = @client.chat(
          parameters: {
            model: @model,
            messages: [
              {
                role: "system",
                content: "You are a prompt quality analyzer. Rate the relevance and focus of the given prompt on a scale of 0.0 to 1.0, where 1.0 means highly relevant and focused, and 0.0 means completely irrelevant or unfocused. Respond with just the numeric score."
              },
              {
                role: "user",
                content: "Analyze this prompt for relevance and focus:\n\n#{prompt}"
              }
            ],
            temperature: 0.1,
            max_tokens: 10
          }
        )

        pp response if @config["log_level"] == "debug"
        score_text = response.dig("choices", 0, "message", "content").to_s.strip
        score = extract_score(score_text)

        {
          relevance_score: score,
          raw_response: score_text
        }
      rescue StandardError => e
        puts "Warning: Content analysis failed: #{e.message}" if @config["log_level"] == "debug"
        { relevance_score: 0.5, raw_response: "Analysis failed" }
      end

      # Basic fact-checking implementation
      def fact_check(statement)
        response = @client.chat(
          parameters: {
            model: @model,
            messages: [
              {
                role: "system",
                content: "You are a fact-checker. Evaluate the accuracy of the given statement. Respond with 'TRUE' if accurate, 'FALSE' if inaccurate, or 'UNKNOWN' if uncertain. Then provide a confidence score from 0.0 to 1.0."
              },
              {
                role: "user",
                content: "Fact-check this statement: #{statement}"
              }
            ],
            temperature: 0.1,
            max_tokens: 50
          }
        )

        result = response.dig("choices", 0, "message", "content").to_s.strip
        parse_fact_check_result(result)
      rescue StandardError => e
        puts "Warning: Fact-checking failed: #{e.message}" if @config["log_level"] == "debug"
        { accurate: true, confidence: 0.5, reason: "Fact-checking unavailable" }
      end

      private

      def get_embedding(text)
        response = @client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: text
          }
        )
        response.dig("data", 0, "embedding")
      end

      def cosine_similarity(vec1, vec2)
        return 0.0 unless vec1 && vec2 && vec1.length == vec2.length

        dot_product = vec1.zip(vec2).map { |a, b| a * b }.sum
        magnitude1 = Math.sqrt(vec1.map { |x| x * x }.sum)
        magnitude2 = Math.sqrt(vec2.map { |x| x * x }.sum)

        return 0.0 if magnitude1 == 0 || magnitude2 == 0

        dot_product / (magnitude1 * magnitude2)
      end

      def fallback_similarity(text1, text2)
        # Simple word overlap similarity as fallback
        words1 = text1.downcase.scan(/\w+/)
        words2 = text2.downcase.scan(/\w+/)

        return 0.0 if words1.empty? || words2.empty?

        intersection = (words1 & words2).length
        union = (words1 | words2).length

        intersection.to_f / union
      end

      def extract_score(text)
        # Extract numeric score from response
        match = text.match(/(\d+\.?\d*)/)
        return 0.5 unless match

        score = match[1].to_f
        # Normalize if score appears to be out of 0-1 range
        score /= 10.0 if score > 1.0 && score <= 10.0
        score /= 100.0 if score > 10.0

        [[score, 0.0].max, 1.0].min
      end

      def parse_fact_check_result(result)
        lines = result.split("\n").map(&:strip)
        accuracy_line = lines.first.to_s.upcase

        accurate = case accuracy_line
                   when /TRUE/ then true
                   when /FALSE/ then false
                   else true # Default to true for unknown
                   end

        # Extract confidence score
        confidence = 0.5
        confidence_match = result.match(/(\d+\.?\d*)/)
        if confidence_match
          confidence = confidence_match[1].to_f
          confidence /= 100.0 if confidence > 1.0
        end

        {
          accurate: accurate,
          confidence: [[confidence, 0.0].max, 1.0].min,
          reason: result
        }
      end
    end
  end
end
