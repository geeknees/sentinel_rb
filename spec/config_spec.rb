# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentinelRb::Config do
  let(:temp_config_file) { "spec_test_config.yml" }

  after do
    File.delete(temp_config_file) if File.exist?(temp_config_file)
  end

  describe ".load" do
    context "when config file exists" do
      before do
        config_content = {
          "provider" => "openai",
          "model" => "gpt-3.5-turbo",
          "relevance_threshold" => 0.7,
          "custom_setting" => "test_value"
        }
        File.write(temp_config_file, config_content.to_yaml)
      end

      it "loads configuration from file" do
        config = described_class.load(temp_config_file)
        
        expect(config.provider).to eq("openai")
        expect(config.model).to eq("gpt-3.5-turbo")
        expect(config.relevance_threshold).to eq(0.7)
        expect(config["custom_setting"]).to eq("test_value")
      end

      it "merges with default configuration" do
        config = described_class.load(temp_config_file)
        
        # Should have custom values
        expect(config.model).to eq("gpt-3.5-turbo")
        # Should have defaults for unspecified values
        expect(config["dangerous_tools"]).to include("delete_file")
      end
    end

    context "when config file does not exist" do
      it "uses default configuration" do
        config = described_class.load("nonexistent.yml")
        
        expect(config.provider).to eq("openai")
        expect(config.model).to eq("gpt-4o-mini")
        expect(config.relevance_threshold).to eq(0.55)
      end
    end

    context "when config file is invalid" do
      before do
        File.write(temp_config_file, "invalid: yaml: content: [")
      end

      it "falls back to default configuration" do
        config = described_class.load(temp_config_file)
        
        expect(config.provider).to eq("openai")
        expect(config.model).to eq("gpt-4o-mini")
      end
    end
  end

  describe "#[]" do
    let(:config) { described_class.new({ "test_key" => "test_value" }) }

    it "accesses configuration values" do
      expect(config["test_key"]).to eq("test_value")
    end
  end

  describe "#api_key_env" do
    context "when api_key_env is specified" do
      let(:config) { described_class.new({ "api_key_env" => "CUSTOM_API_KEY" }) }

      it "returns the specified environment variable name" do
        expect(config.api_key_env).to eq("CUSTOM_API_KEY")
      end
    end

    context "when api_key_env is not specified" do
      let(:config) { described_class.new({}) }

      it "returns the default environment variable name" do
        expect(config.api_key_env).to eq("OPENAI_API_KEY")
      end
    end
  end

  describe "#to_h" do
    let(:config_hash) { { "provider" => "openai", "model" => "gpt-4" } }
    let(:config) { described_class.new(config_hash) }

    it "returns a copy of the configuration hash" do
      result = config.to_h
      
      expect(result).to eq(config_hash)
      expect(result).not_to be(config_hash) # Should be a copy
    end
  end
end
