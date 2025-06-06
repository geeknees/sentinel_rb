# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Analyzers
    # A3: Few-shot Bias Detection
    # Detects potential bias in few-shot examples that could skew model outputs
    class FewShotBias < Base
      ANALYZER_ID = "A3"

      def call
        findings = []

        # Look for example patterns in the prompt
        if has_examples?(@prompt)
          # Check for gender bias patterns
          findings.concat(check_simple_gender_bias(@prompt))
        end

        findings
      end

      private

      def has_examples?(prompt)
        example_indicators = [
          /example\s*\d*:/i,
          /input:\s*.+output:/i,
          /q:\s*.+a:/i
        ]

        example_indicators.any? { |pattern| prompt.match?(pattern) }
      end

      def check_simple_gender_bias(prompt)
        findings = []

        # Count gender pronouns
        male_count = prompt.scan(/\b(he|him|his|man|men|male)\b/i).length
        female_count = prompt.scan(/\b(she|her|hers|woman|women|female)\b/i).length

        total_gender = male_count + female_count
        return findings if total_gender < 3 # Need at least 3 references to detect bias

        # Check for significant imbalance
        max_count = [male_count, female_count].max
        bias_ratio = max_count.to_f / total_gender
        divergence_threshold = @config["divergence_threshold"] || 0.25

        if bias_ratio > (1.0 - divergence_threshold)
          dominant_gender = male_count > female_count ? "male" : "female"
          findings << create_finding(
            id: ANALYZER_ID,
            level: :warn,
            message: "Few-shot examples show potential gender bias (#{(bias_ratio * 100).round(1)}% #{dominant_gender} references)",
            details: {
              male_references: male_count,
              female_references: female_count,
              bias_ratio: bias_ratio.round(3),
              threshold: divergence_threshold,
              suggestions: [
                "Include more balanced gender representation in examples",
                "Use gender-neutral examples when possible",
                "Vary pronouns and names across examples"
              ]
            }
          )
        end

        findings
      end
    end
  end
end
