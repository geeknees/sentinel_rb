# frozen_string_literal: true

module SentinelRb
  module Client
    # Base class for LLM client implementations
    class Base
      def initialize(config)
        @config = config
      end

      # Abstract method: Calculate semantic similarity between two texts
      # @param text1 [String] First text
      # @param text2 [String] Second text
      # @return [Float] Similarity score between 0.0 and 1.0
      def similarity(text1, text2)
        raise NotImplementedError, "Subclasses must implement #similarity"
      end

      # Abstract method: Check factual accuracy of a statement
      # @param statement [String] Statement to fact-check
      # @return [Hash] Result with :accurate boolean and :confidence score
      def fact_check(statement)
        raise NotImplementedError, "Subclasses must implement #fact_check"
      end

      # Abstract method: Analyze content for relevance and quality
      # @param prompt [String] Prompt text to analyze
      # @return [Hash] Analysis results
      def analyze_content(prompt)
        raise NotImplementedError, "Subclasses must implement #analyze_content"
      end
    end
  end
end
