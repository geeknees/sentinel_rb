# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Analyzers
    # A2: Misinformation Detection
    # Detects prompts that may contain or encourage the generation of misinformation
    class Misinformation < Base
      def initialize(prompt, config, client)
        super
        @fact_check_threshold = config["fact_check_threshold"] || 0.7
        @misinformation_keywords = config["misinformation_keywords"] || default_misinformation_keywords
      end

      def call
        analyze(@prompt)
      end

      def analyze(prompt)
        findings = []

        # Check for explicit misinformation instruction patterns
        findings.concat(check_misinformation_instructions(prompt))

        # Check for conspiracy theory keywords
        findings.concat(check_conspiracy_patterns(prompt))

        # Check for medical/health misinformation patterns
        findings.concat(check_medical_misinformation(prompt))

        # For statements that claim to be facts, attempt fact-checking
        findings.concat(check_factual_claims(prompt))

        findings
      end

      private

      def check_misinformation_instructions(prompt)
        findings = []

        instruction_patterns = [
          {
            pattern: /\b(spread|share|promote|tell people|convince others).{0,20}(false|fake|untrue|misleading)\b/i,
            message: "Prompt appears to instruct spreading of false information",
            level: :error
          },
          {
            pattern: /\b(ignore|disregard|dismiss).{0,20}(facts|evidence|science|experts)\b/i,
            message: "Prompt encourages ignoring factual evidence",
            level: :warn
          },
          {
            pattern: /\b(make up|fabricate|invent|create fake).{0,20}(facts|statistics|studies|evidence)\b/i,
            message: "Prompt requests fabrication of false evidence",
            level: :error
          }
        ]

        instruction_patterns.each do |pattern_info|
          matches = prompt.scan(pattern_info[:pattern])
          if matches.any?
            findings << create_finding(
              id: "A2",
              level: pattern_info[:level],
              message: pattern_info[:message],
              details: {
                pattern_matched: pattern_info[:pattern].source,
                matches: matches.flatten.uniq
              }
            )
          end
        end

        findings
      end

      def check_conspiracy_patterns(prompt)
        findings = []

        conspiracy_patterns = [
          /\b(covid.{0,10}hoax|vaccine.{0,10}dangerous|5g.{0,10}virus)\b/i,
          /\b(flat.{0,5}earth|moon.{0,10}landing.{0,10}fake)\b/i,
          /\b(chemtrails|lizard.{0,5}people|illuminati.{0,10}control)\b/i,
          /\b(election.{0,10}(stolen|rigged)|deep.{0,5}state)\b/i
        ]

        conspiracy_count = 0
        matched_patterns = []

        conspiracy_patterns.each do |pattern|
          matches = prompt.scan(pattern)
          if matches.any?
            conspiracy_count += matches.length
            matched_patterns.concat(matches.flatten)
          end
        end

        if conspiracy_count > 0
          findings << create_finding(
            id: "A2",
            level: conspiracy_count >= 3 ? :error : :warn,
            message: "Prompt contains conspiracy theory references (#{conspiracy_count} instances)",
            details: {
              conspiracy_count: conspiracy_count,
              matched_patterns: matched_patterns.uniq,
              suggestions: [
                "Consider removing conspiracy theory references",
                "Focus on factual, evidence-based information",
                "Verify claims with reliable sources"
              ]
            }
          )
        end

        findings
      end

      def check_medical_misinformation(prompt)
        findings = []

        medical_misinformation_patterns = [
          {
            pattern: /\b(cure|heal|treat).{0,20}(cancer|diabetes|covid|aids).{0,20}(naturally|home remedy|without medicine)\b/i,
            message: "Prompt contains potential medical misinformation about cures",
            level: :error
          },
          {
            pattern: /\b(vaccines?.{0,10}(cause|dangerous|harmful|toxic))\b/i,
            message: "Prompt contains anti-vaccine misinformation",
            level: :error
          },
          {
            pattern: /\b(doctors?.{0,10}(hiding|concealing).{0,20}(truth|cure))\b/i,
            message: "Prompt promotes medical conspiracy theories",
            level: :warn
          }
        ]

        medical_misinformation_patterns.each do |pattern_info|
          matches = prompt.scan(pattern_info[:pattern])
          if matches.any?
            findings << create_finding(
              id: "A2",
              level: pattern_info[:level],
              message: pattern_info[:message],
              details: {
                pattern_matched: pattern_info[:pattern].source,
                matches: matches.flatten.uniq,
                suggestions: [
                  "Remove medical misinformation claims",
                  "Consult qualified medical professionals",
                  "Use evidence-based medical information"
                ]
              }
            )
          end
        end

        findings
      end

      def check_factual_claims(prompt)
        findings = []

        # Look for statements that make factual claims
        factual_claim_patterns = [
          /studies show that/i,
          /research proves/i,
          /scientists have found/i,
          /according to experts/i,
          /statistics indicate/i
        ]

        claims_found = []
        factual_claim_patterns.each do |pattern|
          matches = prompt.scan(/[^.!?]*#{pattern}[^.!?]*[.!?]/)
          claims_found.concat(matches) if matches.any?
        end

        if claims_found.any? && claims_found.length <= 3  # Don't fact-check too many claims
          claims_found.each do |claim|
            begin
              fact_check_result = @client.fact_check(claim.strip)

              if fact_check_result[:confidence] < @fact_check_threshold
                findings << create_finding(
                  id: "A2",
                  level: :info,
                  message: "Factual claim could not be verified with high confidence",
                  details: {
                    claim: claim.strip,
                    confidence: fact_check_result[:confidence],
                    reason: fact_check_result[:reason],
                    suggestions: [
                      "Verify the claim with reliable sources",
                      "Consider adding source citations",
                      "Use more cautious language for unverified claims"
                    ]
                  }
                )
              end
            rescue StandardError => e
              # Fact-checking failed, but don't break the analysis
              puts "Debug: Fact-checking failed for claim: #{e.message}" if ENV['DEBUG']
            end
          end
        end

        findings
      end

      def default_misinformation_keywords
        [
          "fake news", "hoax", "conspiracy", "cover-up", "they don't want you to know",
          "mainstream media lies", "suppressed truth", "hidden agenda", "false flag"
        ]
      end
    end
  end
end
