# frozen_string_literal: true

module SentinelRb
  module Analyzers
    # Base class for all prompt analyzers
    class Base
      attr_reader :prompt, :config, :client

      def initialize(prompt, config, client)
        @prompt = prompt
        @config = config
        @client = client
      end

      # Abstract method: Perform analysis on the prompt
      # @return [Array<Hash>] Array of findings with :id, :level, :message keys
      def call
        raise NotImplementedError, "Subclasses must implement #call"
      end

      protected

      # Helper method to create standardized finding hash
      # @param id [String] Analyzer ID (e.g., 'A1')
      # @param level [Symbol] Severity level (:info, :warn, :error, :critical)
      # @param message [String] Human-readable description of the finding
      # @param details [Hash] Additional details about the finding
      # @return [Hash] Standardized finding hash
      def create_finding(id:, level:, message:, details: {})
        {
          id: id,
          level: level,
          message: message,
          details: details,
          analyzer: self.class.name.split("::").last
        }
      end

      # Helper method to check if a threshold is exceeded
      # @param score [Float] The score to check
      # @param threshold [Float] The threshold value
      # @param higher_is_better [Boolean] Whether higher scores are better
      # @return [Boolean] True if threshold is exceeded
      def threshold_exceeded?(score, threshold, higher_is_better: true)
        if higher_is_better
          score < threshold
        else
          score > threshold
        end
      end
    end
  end
end
