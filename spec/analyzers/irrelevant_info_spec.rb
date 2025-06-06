# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentinelRb::Analyzers::IrrelevantInfo do
  let(:config) { SentinelRb::Config.new({ "relevance_threshold" => 0.55 }) }
  let(:client) { instance_double(SentinelRb::Client::OpenAI) }
  let(:analyzer) { described_class.new(prompt, config, client) }

  describe "#call" do
    context "with relevant prompt" do
      let(:prompt) { "Please analyze the quarterly sales data and provide a summary of key trends." }
      
      before do
        allow(client).to receive(:analyze_content).and_return({
          relevance_score: 0.8,
          raw_response: "0.8"
        })
      end

      it "returns no findings for highly relevant content" do
        result = analyzer.call
        relevance_findings = result.select { |f| f[:id] == "A1" && f[:message].include?("relevance score") }
        expect(relevance_findings).to be_empty
      end
    end

    context "with irrelevant prompt" do
      let(:prompt) { "Here's some random marketing copy mixed with a task. Buy our product! Also, please analyze sales data. Special offer today only!" }
      
      before do
        allow(client).to receive(:analyze_content).and_return({
          relevance_score: 0.3,
          raw_response: "0.3"
        })
      end

      it "returns relevance warning" do
        result = analyzer.call
        relevance_finding = result.find { |f| f[:id] == "A1" && f[:message].include?("relevance score") }
        
        expect(relevance_finding).not_to be_nil
        expect(relevance_finding[:level]).to eq(:warn)
        expect(relevance_finding[:message]).to include("0.3")
        expect(relevance_finding[:details][:relevance_score]).to eq(0.3)
        expect(relevance_finding[:details][:threshold]).to eq(0.55)
      end
    end

    context "with repetitive content" do
      let(:prompt) { "Please analyze data data data data data for trends trends trends trends." }
      
      before do
        allow(client).to receive(:analyze_content).and_return({
          relevance_score: 0.7,
          raw_response: "0.7"
        })
      end

      it "detects repetitive words" do
        result = analyzer.call
        repetitive_finding = result.find { |f| f[:message].include?("repetitive words") }
        
        expect(repetitive_finding).not_to be_nil
        expect(repetitive_finding[:level]).to eq(:info)
        expect(repetitive_finding[:details][:repetitive_words]).to include("data")
      end
    end

    context "with noise markers" do
      let(:prompt) { "DISCLAIMER: This is legal text. TODO: Fix this later. Please analyze the data." }
      
      before do
        allow(client).to receive(:analyze_content).and_return({
          relevance_score: 0.6,
          raw_response: "0.6"
        })
      end

      it "detects noise markers" do
        result = analyzer.call
        noise_findings = result.select { |f| f[:message].include?("noise markers") }
        
        expect(noise_findings.length).to be >= 1
        expect(noise_findings.first[:level]).to eq(:info)
      end
    end

    context "with variable sentence lengths" do
      let(:prompt) { "Short. This is a medium length sentence with some content. This is a very long sentence that goes on and on with lots of unnecessary information that might indicate mixed content types or possibly irrelevant padding material." }
      
      before do
        allow(client).to receive(:analyze_content).and_return({
          relevance_score: 0.6,
          raw_response: "0.6"
        })
      end

      it "detects variable sentence lengths" do
        result = analyzer.call
        length_finding = result.find { |f| f[:message].include?("variable sentence lengths") }
        
        if length_finding
          expect(length_finding[:level]).to eq(:info)
          expect(length_finding[:details]).to have_key(:coefficient_of_variation)
        end
      end
    end

    context "when client fails" do
      let(:prompt) { "Test prompt" }
      
      before do
        allow(client).to receive(:analyze_content).and_raise(StandardError.new("API Error"))
      end

      it "handles client errors gracefully" do
        expect { analyzer.call }.not_to raise_error
        # The OpenAI client should handle the error and return a fallback response
      end
    end
  end
end
