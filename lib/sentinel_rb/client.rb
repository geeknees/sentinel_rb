# frozen_string_literal: true

require_relative "client/base"
require_relative "client/openai"
require_relative "client/mock"

module SentinelRb
  module Client
    # Factory for creating LLM client instances
    class Factory
      def self.create(config)
        provider = config.provider
        
        case provider
        when "openai"
          OpenAI.new(config)
        when "mock"
          Mock.new(config)
        else
          raise ArgumentError, "Unsupported provider: #{provider}. Supported providers: openai, mock"
        end
      end
    end
  end
end
