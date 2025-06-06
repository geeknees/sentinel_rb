# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Analyzers
    # A4: Base Model Usage Detection
    # Detects prompts that may be attempting to use base models inappropriately
    # or trying to bypass safety measures
    class BaseModelUsage < Base
      def initialize(prompt, config, client)
        super
        @instruction_keywords = config["instruction_keywords"] || default_instruction_keywords
        @bypass_patterns = config["bypass_patterns"] || default_bypass_patterns
      end

      def call
        analyze(@prompt)
      end

      def analyze(prompt)
        findings = []

        # Check for base model instruction patterns
        findings.concat(check_base_model_instructions(prompt))

        # Check for safety bypass attempts
        findings.concat(check_safety_bypass_patterns(prompt))

        # Check for role-playing that might bypass guidelines
        findings.concat(check_inappropriate_roleplay(prompt))

        # Check for attempts to access training data
        findings.concat(check_training_data_access(prompt))

        findings
      end

      private

      def check_base_model_instructions(prompt)
        findings = []

        instruction_patterns = [
          {
            pattern: /\b(ignore|disregard|forget).{0,20}(instructions|guidelines|rules|constraints)\b/i,
            message: "Prompt attempts to bypass model instructions",
            level: :error
          },
          {
            pattern: /\b(act as|pretend to be|you are now).{0,50}(uncensored|unfiltered|unrestricted)\b/i,
            message: "Prompt attempts to create uncensored behavior",
            level: :error
          },
          {
            pattern: /\b(jailbreak|prompt injection|escape|hack).{0,20}(model|system|AI)\b/i,
            message: "Prompt contains explicit jailbreaking language",
            level: :error
          }
        ]

        instruction_patterns.each do |pattern_info|
          if prompt.match?(pattern_info[:pattern])
            findings << create_finding(
              id: "A4",
              level: pattern_info[:level],
              message: pattern_info[:message],
              details: {
                pattern_matched: pattern_info[:pattern].source,
                suggestion: "Remove attempts to bypass model guidelines and use appropriate prompting techniques"
              }
            )
          end
        end

        findings
      end

      def check_safety_bypass_patterns(prompt)
        findings = []

        bypass_patterns = [
          {
            pattern: /\b(DAN|do anything now|opposite day|evil mode)\b/i,
            message: "Prompt uses known jailbreak technique",
            level: :error
          },
          {
            pattern: /\b(hypothetically|theoretically|in fiction|imagine if).{0,30}(illegal|harmful|dangerous)\b/i,
            message: "Prompt may be attempting to circumvent safety through hypothetical framing",
            level: :warn
          },
          {
            pattern: /\b(roleplay|pretend).{0,50}(no limits|no restrictions|anything goes)\b/i,
            message: "Prompt uses roleplay to bypass restrictions",
            level: :warn
          }
        ]

        bypass_patterns.each do |pattern_info|
          if prompt.match?(pattern_info[:pattern])
            findings << create_finding(
              id: "A4",
              level: pattern_info[:level],
              message: pattern_info[:message],
              details: {
                pattern_matched: pattern_info[:pattern].source,
                suggestion: "Use direct, honest prompting instead of attempting to circumvent safety measures"
              }
            )
          end
        end

        findings
      end

      def check_inappropriate_roleplay(prompt)
        findings = []

        # Check for potentially problematic roleplay scenarios
        problematic_roles = [
          /\b(criminal|terrorist|hacker|nazi|supremacist)\b/i,
          /\b(drug dealer|arms dealer|human trafficker)\b/i,
          /\b(dictator|tyrant|oppressor)\b/i
        ]

        if prompt.match?(/\b(roleplay|act as|pretend to be|you are)\b/i)
          problematic_roles.each do |role_pattern|
            if prompt.match?(role_pattern)
              findings << create_finding(
                id: "A4",
                level: :warn,
                message: "Prompt involves roleplay as potentially harmful persona",
                details: {
                  role_pattern: role_pattern.source,
                  suggestion: "Consider using more appropriate roleplay scenarios that don't involve harmful personas"
                }
              )
            end
          end
        end

        findings
      end

      def check_training_data_access(prompt)
        findings = []

        training_access_patterns = [
          /\b(repeat|recite|reproduce).{0,20}(training data|dataset|examples)\b/i,
          /\b(what did you learn|show me examples).{0,30}(from training|during training)\b/i,
          /\b(memorized|remember).{0,20}(from your training|specific examples)\b/i
        ]

        training_access_patterns.each do |pattern|
          if prompt.match?(pattern)
            findings << create_finding(
              id: "A4",
              level: :info,
              message: "Prompt may be attempting to access specific training data",
              details: {
                pattern_matched: pattern.source,
                suggestion: "Focus on asking for general information rather than specific training examples"
              }
            )
          end
        end

        findings
      end

      def default_instruction_keywords
        %w[
          ignore disregard forget bypass circumvent
          uncensored unfiltered unrestricted unlimited
          jailbreak hack override disable
        ]
      end

      def default_bypass_patterns
        [
          "DAN", "do anything now", "opposite day", "evil mode",
          "developer mode", "god mode", "admin mode"
        ]
      end
    end
  end
end
