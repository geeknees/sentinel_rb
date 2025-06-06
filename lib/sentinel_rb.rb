# frozen_string_literal: true

require_relative "sentinel_rb/version"
require_relative "sentinel_rb/config"
require_relative "sentinel_rb/client"
require_relative "sentinel_rb/analyzer"
require_relative "sentinel_rb/report"
require_relative "sentinel_rb/cli"

module SentinelRb
  class Error < StandardError; end

  # Main entry point for programmatic usage
  def self.analyze(prompt_or_file, config: nil, **options)
    analyzer = Analyzer.new(config)
    
    if File.exist?(prompt_or_file.to_s)
      analyzer.analyze_file(prompt_or_file, **options)
    else
      findings = analyzer.analyze_prompt(prompt_or_file.to_s, **options)
      {
        content: prompt_or_file,
        findings: findings,
        analyzed_at: Time.now
      }
    end
  end

  # Analyze multiple files matching a pattern
  def self.analyze_files(pattern, config: nil, **options)
    analyzer = Analyzer.new(config)
    analyzer.analyze_files(pattern, **options)
  end

  # Load configuration from file
  def self.load_config(path = ".sentinel.yml")
    Config.load(path)
  end
end
