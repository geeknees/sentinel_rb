# frozen_string_literal: true

require_relative "base"

module SentinelRb
  module Analyzers
    # A5: Dangerous Tools Detection
    # Detects prompts that reference potentially dangerous tools, techniques, or requests
    class DangerousTools < Base
      def initialize(prompt, config, client)
        super
        @dangerous_keywords = config["dangerous_keywords"] || default_dangerous_keywords
        @weapon_keywords = config["weapon_keywords"] || default_weapon_keywords
        @cyber_keywords = config["cyber_keywords"] || default_cyber_keywords
      end

      def call
        analyze(@prompt)
      end

      def analyze(prompt)
        findings = []

        # Check for weapon/explosive creation requests
        findings.concat(check_weapon_creation(prompt))

        # Check for cyber attack tools/techniques
        findings.concat(check_cyber_attacks(prompt))

        # Check for illegal substance creation
        findings.concat(check_illegal_substances(prompt))

        # Check for financial fraud techniques
        findings.concat(check_financial_fraud(prompt))

        # Check for identity theft/privacy violations
        findings.concat(check_privacy_violations(prompt))

        findings
      end

      private

      def check_weapon_creation(prompt)
        findings = []

        weapon_patterns = [
          {
            pattern: /\b(how to make|create|build|manufacture).{0,50}(bomb|explosive|grenade|weapon)\b/i,
            message: "Prompt requests instructions for creating weapons or explosives",
            level: :error
          },
          {
            pattern: /\b(recipe|instructions|guide).{0,30}(explosive|bomb|poison|toxin)\b/i,
            message: "Prompt requests dangerous substance recipes",
            level: :error
          },
          {
            pattern: /\b(3d print|print).{0,20}(gun|weapon|firearm)\b/i,
            message: "Prompt references 3D printing weapons",
            level: :error
          }
        ]

        weapon_patterns.each do |pattern_info|
          next unless prompt.match?(pattern_info[:pattern])

          findings << create_finding(
            id: "A5",
            level: pattern_info[:level],
            message: pattern_info[:message],
            details: {
              category: "weapons",
              pattern_matched: pattern_info[:pattern].source,
              suggestion: "Avoid requesting information about creating dangerous weapons or substances"
            }
          )
        end

        findings
      end

      def check_cyber_attacks(prompt)
        findings = []

        cyber_patterns = [
          {
            pattern: /\b(hack|exploit|penetrate|breach).{0,30}(system|network|database|server)\b/i,
            message: "Prompt references hacking or system exploitation",
            level: :warn
          },
          {
            pattern: /\b(ddos|denial of service|botnet|malware|ransomware)\b/i,
            message: "Prompt references cyber attack tools or techniques",
            level: :error
          },
          {
            pattern: /\b(sql injection|xss|cross site|buffer overflow)\b/i,
            message: "Prompt references specific attack vectors",
            level: :warn
          },
          {
            pattern: /\b(keylogger|trojan|backdoor|rootkit)\b/i,
            message: "Prompt references malicious software types",
            level: :error
          }
        ]

        cyber_patterns.each do |pattern_info|
          next unless prompt.match?(pattern_info[:pattern])

          findings << create_finding(
            id: "A5",
            level: pattern_info[:level],
            message: pattern_info[:message],
            details: {
              category: "cyber_security",
              pattern_matched: pattern_info[:pattern].source,
              suggestion: "For security education, use ethical hacking resources and controlled environments"
            }
          )
        end

        findings
      end

      def check_illegal_substances(prompt)
        findings = []

        substance_patterns = [
          {
            pattern: /\b(how to make|synthesize|produce|manufacture).{0,50}(meth|cocaine|heroin|fentanyl|lsd)\b/i,
            message: "Prompt requests illegal drug manufacturing information",
            level: :error
          },
          {
            pattern: /\b(recipe|synthesis|production).{0,30}(amphetamine|mdma|ecstasy)\b/i,
            message: "Prompt seeks controlled substance production methods",
            level: :error
          },
          {
            pattern: /\b(grow|cultivate).{0,20}(cannabis|marijuana).{0,30}(illegal|hidden)\b/i,
            message: "Prompt references illegal cultivation methods",
            level: :warn
          }
        ]

        substance_patterns.each do |pattern_info|
          next unless prompt.match?(pattern_info[:pattern])

          findings << create_finding(
            id: "A5",
            level: pattern_info[:level],
            message: pattern_info[:message],
            details: {
              category: "illegal_substances",
              pattern_matched: pattern_info[:pattern].source,
              suggestion: "Seek information about substance abuse prevention and treatment resources instead"
            }
          )
        end

        findings
      end

      def check_financial_fraud(prompt)
        findings = []

        fraud_patterns = [
          {
            pattern: /\b(credit card|debit card).{0,30}(fraud|scam|steal|clone)\b/i,
            message: "Prompt references credit card fraud techniques",
            level: :error
          },
          {
            pattern: /\b(phishing|social engineering).{0,30}(bank|financial|password)\b/i,
            message: "Prompt references financial phishing techniques",
            level: :warn
          },
          {
            pattern: /\b(money laundering|tax evasion|embezzlement)\b/i,
            message: "Prompt references financial crimes",
            level: :warn
          },
          {
            pattern: /\b(counterfeit|fake).{0,20}(money|currency|bills)\b/i,
            message: "Prompt references counterfeiting currency",
            level: :error
          }
        ]

        fraud_patterns.each do |pattern_info|
          next unless prompt.match?(pattern_info[:pattern])

          findings << create_finding(
            id: "A5",
            level: pattern_info[:level],
            message: pattern_info[:message],
            details: {
              category: "financial_fraud",
              pattern_matched: pattern_info[:pattern].source,
              suggestion: "For financial security education, consult legitimate cybersecurity resources"
            }
          )
        end

        findings
      end

      def check_privacy_violations(prompt)
        findings = []

        privacy_patterns = [
          {
            pattern: /\b(dox|doxxing|personal information).{0,30}(find|locate|discover)\b/i,
            message: "Prompt may reference doxxing or privacy violation techniques",
            level: :warn
          },
          {
            pattern: /\b(stalk|stalking|track|surveillance).{0,30}(person|individual|someone)\b/i,
            message: "Prompt references stalking or unauthorized surveillance",
            level: :error
          },
          {
            pattern: /\b(identity theft|impersonate|assume identity)\b/i,
            message: "Prompt references identity theft techniques",
            level: :error
          },
          {
            pattern: /\b(spy|spying|eavesdrop).{0,30}(secretly|hidden|covert)\b/i,
            message: "Prompt references covert surveillance techniques",
            level: :warn
          }
        ]

        privacy_patterns.each do |pattern_info|
          next unless prompt.match?(pattern_info[:pattern])

          findings << create_finding(
            id: "A5",
            level: pattern_info[:level],
            message: pattern_info[:message],
            details: {
              category: "privacy_violation",
              pattern_matched: pattern_info[:pattern].source,
              suggestion: "Respect privacy rights and use legitimate channels for information gathering"
            }
          )
        end

        findings
      end

      def default_dangerous_keywords
        %w[
          bomb explosive weapon gun firearm knife blade
          poison toxin chemical biological nuclear radioactive
          hack exploit malware virus trojan ransomware
          fraud scam phishing counterfeit
          drug cocaine heroin meth amphetamine
        ]
      end

      def default_weapon_keywords
        %w[
          bomb explosive grenade dynamite c4 tnt
          gun pistol rifle shotgun firearm ammunition
          knife blade sword machete weapon
          poison gas chemical biological agent
        ]
      end

      def default_cyber_keywords
        %w[
          hack exploit penetration breach vulnerability
          malware virus trojan backdoor rootkit
          ddos botnet ransomware keylogger spyware
          injection overflow xss csrf
        ]
      end
    end
  end
end
