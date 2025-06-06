# SentinelRb Development Guide

## Development Setup

### Prerequisites
- Ruby >= 3.1.0
- Bundler
- Git

### Initial Setup
```bash
git clone <repository-url>
cd sentinel_rb
bin/setup
```

### Running Tests
```bash
# All tests
rake spec

# Specific test file
rspec spec/analyzers/irrelevant_info_spec.rb

# With coverage
COVERAGE=true rake spec
```

### Development Console
```bash
bin/console
```

## Project Structure

```
sentinel_rb/
├── lib/
│   ├── sentinel_rb.rb           # Main entry point
│   └── sentinel_rb/
│       ├── version.rb           # Version management
│       ├── config.rb           # Configuration loading
│       ├── cli.rb              # Command line interface
│       ├── client/             # LLM client implementations
│       │   ├── base.rb
│       │   ├── openai.rb
│       │   └── anthropic.rb
│       ├── analyzers/          # Analysis modules
│       │   ├── base.rb
│       │   ├── irrelevant_info.rb
│       │   ├── misinformation.rb
│       │   ├── few_shot_bias.rb
│       │   ├── base_model.rb
│       │   └── dangerous_tools.rb
│       ├── report/             # Reporting system
│       │   ├── formatter.rb
│       │   ├── table.rb
│       │   ├── json.rb
│       │   └── detailed.rb
│       └── utils/              # Utility classes
│           ├── file_finder.rb
│           └── prompt_parser.rb
├── spec/                       # Test files
├── docs/                       # Documentation
├── exe/                        # Executable files
└── bin/                        # Development scripts
```

## Adding New Analyzers

### 1. Create Analyzer Class
```ruby
# lib/sentinel_rb/analyzers/your_analyzer.rb
module SentinelRb
  module Analyzers
    class YourAnalyzer < Base
      def call
        # Your analysis logic here
        findings = []

        if condition_met?
          findings << {
            id: 'A6',
            level: :warn,
            message: 'Your custom warning message'
          }
        end

        findings
      end

      private

      def condition_met?
        # Your condition logic
      end
    end
  end
end
```

### 2. Register Analyzer
```ruby
# lib/sentinel_rb.rb
require 'sentinel_rb/analyzers/your_analyzer'

module SentinelRb
  ANALYZERS = {
    'A1' => Analyzers::IrrelevantInfo,
    'A2' => Analyzers::Misinformation,
    'A3' => Analyzers::FewShotBias,
    'A4' => Analyzers::BaseModel,
    'A5' => Analyzers::DangerousTools,
    'A6' => Analyzers::YourAnalyzer  # Add here
  }.freeze
end
```

### 3. Add Tests
```ruby
# spec/analyzers/your_analyzer_spec.rb
require 'spec_helper'

RSpec.describe SentinelRb::Analyzers::YourAnalyzer do
  let(:config) { { 'your_threshold' => 0.5 } }
  let(:client) { instance_double(SentinelRb::Client::OpenAI) }
  let(:analyzer) { described_class.new(prompt, config, client) }

  describe '#call' do
    context 'when condition is met' do
      let(:prompt) { 'test prompt that triggers condition' }

      it 'returns warning' do
        result = analyzer.call
        expect(result).to include(
          hash_including(
            id: 'A6',
            level: :warn,
            message: include('Your custom warning')
          )
        )
      end
    end

    context 'when condition is not met' do
      let(:prompt) { 'normal prompt' }

      it 'returns no findings' do
        result = analyzer.call
        expect(result).to be_empty
      end
    end
  end
end
```

## Adding LLM Providers

### 1. Implement Client Interface
```ruby
# lib/sentinel_rb/client/your_provider.rb
module SentinelRb
  module Client
    class YourProvider < Base
      def initialize(config)
        super
        @api_key = ENV['YOUR_PROVIDER_API_KEY']
        @base_url = config['base_url'] || 'https://api.yourprovider.com'
      end

      def similarity(text1, text2)
        # Implement similarity calculation
      end

      def fact_check(statement)
        # Implement fact checking
      end

      def analyze_content(prompt)
        # Implement content analysis
      end

      private

      def make_request(endpoint, payload)
        # HTTP request implementation
      end
    end
  end
end
```

### 2. Register Provider
```ruby
# lib/sentinel_rb/client.rb
module SentinelRb
  module Client
    PROVIDERS = {
      'openai' => OpenAI,
      'anthropic' => Anthropic,
      'your_provider' => YourProvider  # Add here
    }.freeze

    def self.create(config)
      provider = config['provider']
      client_class = PROVIDERS[provider]
      raise "Unsupported provider: #{provider}" unless client_class

      client_class.new(config)
    end
  end
end
```

## Testing Guidelines

### Unit Tests
- Each analyzer should have comprehensive test coverage
- Mock external API calls
- Test edge cases and error conditions

### Integration Tests
- Test CLI commands end-to-end
- Test configuration loading
- Test file processing pipeline

### Example Test Structure
```ruby
RSpec.describe SentinelRb::Analyzers::IrrelevantInfo do
  let(:config) { { 'relevance_threshold' => 0.55 } }
  let(:client) { instance_double(SentinelRb::Client::OpenAI) }
  let(:analyzer) { described_class.new(prompt, config, client) }

  before do
    allow(client).to receive(:similarity).and_return(similarity_score)
  end

  context 'with relevant prompt' do
    let(:prompt) { 'Clear, focused task description' }
    let(:similarity_score) { 0.8 }

    it 'returns no findings' do
      expect(analyzer.call).to be_empty
    end
  end

  context 'with irrelevant prompt' do
    let(:prompt) { 'Off-topic content mixed with task' }
    let(:similarity_score) { 0.3 }

    it 'returns relevance warning' do
      result = analyzer.call
      expect(result).to include(
        hash_including(
          id: 'A1',
          level: :warn,
          message: include('relevance')
        )
      )
    end
  end
end
```

## Code Style and Conventions

### Ruby Style
- Follow Ruby community style guide
- Use RuboCop for style enforcement
- 2-space indentation
- Maximum line length: 100 characters

### Naming Conventions
- Classes: PascalCase
- Methods: snake_case
- Constants: SCREAMING_SNAKE_CASE
- Files: snake_case

### Documentation
- Use YARD for API documentation
- Include examples in method documentation
- Document all public methods and classes

### Example Documentation
```ruby
# Analyzes prompts for irrelevant information
#
# @param prompt [String] the prompt text to analyze
# @param config [Hash] configuration options
# @param client [Client::Base] LLM client instance
# @return [Array<Hash>] array of findings
#
# @example
#   analyzer = IrrelevantInfo.new(prompt, config, client)
#   findings = analyzer.call
#   findings.each { |f| puts f[:message] }
class IrrelevantInfo < Base
  # Performs the analysis
  #
  # @return [Array<Hash>] findings with :id, :level, :message keys
  def call
    # Implementation
  end
end
```

## Performance Considerations

### Caching
- Implement response caching for repeated API calls
- Use file-based cache for development
- Redis cache for production deployments

### Parallel Processing
- Use thread pools for I/O bound operations
- Implement batch processing for large prompt sets
- Consider memory usage with large files

### Rate Limiting
- Implement respectful rate limiting for API calls
- Configurable delays between requests
- Exponential backoff for failed requests

## Release Process

### Version Management
```bash
# Update version
vim lib/sentinel_rb/version.rb

# Update changelog
vim CHANGELOG.md

# Commit changes
git add -A
git commit -m "Release v1.2.3"

# Tag release
git tag v1.2.3
git push origin main --tags
```

### Gem Publishing
```bash
# Build gem
rake build

# Test gem installation
gem install pkg/sentinel_rb-1.2.3.gem

# Publish to RubyGems
rake release
```

## Contributing Guidelines

### Pull Request Process
1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Update documentation
6. Submit pull request

### Code Review Checklist
- [ ] Tests added for new functionality
- [ ] Documentation updated
- [ ] Performance impact considered
- [ ] Security implications reviewed
- [ ] Backward compatibility maintained

### Issue Reporting
- Use issue templates
- Include reproduction steps
- Provide relevant configuration
- Include error messages and logs
