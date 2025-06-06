# frozen_string_literal: true

require "yaml"

module SentinelRb
  # Configuration management for SentinelRb
  class Config
    DEFAULT_CONFIG = {
      "provider" => "openai",
      "model" => "gpt-4o-mini",
      "relevance_threshold" => 0.55,
      "divergence_threshold" => 0.25,
      "fact_check_threshold" => 0.7,
      "dangerous_tools" => %w[delete_file transfer_funds system_shutdown exec_command],
      "skip_patterns" => ["**/.git/**", "**/node_modules/**", "**/tmp/**"],
      "output_format" => "table",
      "log_level" => "warn"
    }.freeze

    def self.load(config_path = ".sentinel.yml")
      config = DEFAULT_CONFIG.dup

      if File.exist?(config_path)
        begin
          user_config = YAML.load_file(config_path)
          config.merge!(user_config) if user_config.is_a?(Hash)
        rescue Psych::SyntaxError => e
          warn "Warning: Invalid YAML in config file #{config_path}: #{e.message}"
          warn "Using default configuration."
        end
      end

      new(config)
    end

    def initialize(config_hash)
      @config = config_hash
    end

    def [](key)
      @config[key]
    end

    def provider
      @config["provider"]
    end

    def model
      @config["model"]
    end

    def relevance_threshold
      @config["relevance_threshold"]
    end

    def api_key_env
      @config["api_key_env"] || "OPENAI_API_KEY"
    end

    def to_h
      @config.dup
    end
  end
end
