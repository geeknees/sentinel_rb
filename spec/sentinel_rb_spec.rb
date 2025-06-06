# frozen_string_literal: true

RSpec.describe SentinelRb do
  it "has a version number" do
    expect(SentinelRb::VERSION).not_to be nil
  end

  describe ".analyze" do
    let(:test_prompt) { "This is a clear and focused test prompt for analyzing relevance." }
    
    it "analyzes a prompt string" do
      # Mock the OpenAI client to avoid real API calls
      allow_any_instance_of(SentinelRb::Client::OpenAI).to receive(:analyze_content)
        .and_return({ relevance_score: 0.8, raw_response: "0.8" })
      
      result = SentinelRb.analyze(test_prompt)
      
      expect(result).to have_key(:content)
      expect(result).to have_key(:findings)
      expect(result).to have_key(:analyzed_at)
      expect(result[:content]).to eq(test_prompt)
    end
  end

  describe ".load_config" do
    it "loads default configuration when no file exists" do
      config = described_class.load_config("nonexistent.yml")
      
      expect(config.provider).to eq("openai")
      expect(config.relevance_threshold).to eq(0.55)
    end
  end
end
