# SentinelRb

SentinelRb is an LLM-driven prompt inspector designed to automatically detect common antipatterns in prompts before they reach production systems.

## Overview

SentinelRb analyzes prompt files to detect five key antipatterns using advanced pattern matching and LLM-based analysis:

| ID | Target | Detection Logic |
|----|--------|-----------------|
| A1 | Irrelevant Information | Uses LLM to generate relevance scores; flags prompts with low focus/clarity |
| A2 | Misinformation & Logical Contradictions | Detects false information patterns and conspiracy theories |
| A3 | Few-shot Bias | Analyzes example patterns for demographic or representational bias |
| A4 | Base Model Usage | Detects jailbreak attempts and instruction bypassing |
| A5 | Dangerous Tools | Identifies requests for harmful content creation or dangerous activities |

## Features

- **Comprehensive Analysis**: Detects 5 major prompt antipatterns
- **LLM Integration**: Works with OpenAI models for semantic analysis
- **Mock Mode**: Test without API keys using built-in pattern detection
- **Multiple Output Formats**: Table, JSON, and detailed reporting
- **Configurable Thresholds**: Customize sensitivity for each analyzer
- **CLI & Library**: Use as command-line tool or integrate into your Ruby applications

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sentinel_rb'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install sentinel_rb
```

## Requirements

- Ruby >= 3.1.0
- OpenAI API key (optional - mock mode available for testing)

## Usage

### CLI Usage

Analyze prompt files using the command-line interface:

```bash
# Analyze all markdown files in prompts directory
sentinel_rb analyze --glob "prompts/**/*.md"

# Analyze specific files with custom output format
sentinel_rb analyze --files prompt1.md prompt2.md --format json

# Run specific analyzers only
sentinel_rb analyze --files test.md --analyzers A1,A2,A5

# Use detailed output format
sentinel_rb analyze --files test.md --format detailed
```

### Library Usage

Use SentinelRb programmatically in your Ruby applications:

```ruby
require 'sentinel_rb'

# Initialize analyzer with custom config
config = SentinelRb::Config.load('.sentinel.yml')
analyzer = SentinelRb::Analyzer.new(config)

# Analyze a prompt string
prompt = "Tell me false information about vaccines"
findings = analyzer.analyze_prompt(prompt)

# Analyze a file
findings = analyzer.analyze_file('prompt.md')

# Run specific analyzers only
findings = analyzer.analyze_prompt(prompt, analyzer_ids: ['A2', 'A4'])

findings.each do |finding|
  puts "#{finding[:level]}: #{finding[:message]}"
end
```

### Configuration

Create a `.sentinel.yml` file in your project root:

```yaml
# LLM Provider
provider: openai                    # or 'mock' for testing
model: gpt-4o-mini
api_key_env: OPENAI_API_KEY

# Analysis Thresholds
relevance_threshold: 0.55          # A1: Lower = more strict
divergence_threshold: 0.25         # A3: Lower = more strict  
fact_check_threshold: 0.7          # A2: Higher = more strict

# Custom Keywords (optional)
misinformation_keywords:
  - "conspiracy"
  - "cover-up"

dangerous_keywords:
  - "exploit"
  - "malware"

# File Processing
skip_patterns:
  - "**/.git/**"
  - "**/node_modules/**"
```

### Mock Mode (No API Key Required)

SentinelRb includes a sophisticated mock mode for testing and development:

```yaml
# .sentinel.yml
provider: mock
```

The mock client provides:
- Pattern-based detection for all analyzers
- Simulated relevance scoring with built-in heuristics
- No external API calls required
- Consistent results for CI/CD pipelines

### Output Formats

#### Table Format (Default)
```
📄 prompt.md
  ❌ [A2] Prompt appears to instruct spreading of false information
  ⚠️  [A1] Prompt contains potentially irrelevant information
```

#### JSON Format
```bash
sentinel_rb analyze --files prompt.md --format json
```

#### Detailed Format
```bash
sentinel_rb analyze --files prompt.md --format detailed
```
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { ruby-version: 3.3 }
      - run: gem install sentinel_rb
      - name: Run Sentinel
        env: { OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }} }
        run: |
          sentinel --glob "prompts/**/*" --config .sentinel.yml --format table
```

## Architecture

SentinelRb consists of these key components:

- **Config**: Loads settings from `.sentinel.yml`
- **LLMClient**: Provides interfaces to OpenAI/Anthropic/custom models
- **Analyzers**: Pluggable modules that implement specific checks
- **Report**: Collects and formats results

### Analyzer Structure

Each analyzer inherits from a base class and implements a `call` method:

```ruby
class SentinelRb::Analyzers::Base
  def initialize(prompt, config, client); end
  def call   # => [{id:, level:, message:}, ...]
end
```

Example analyzer implementation:

```ruby
class SentinelRb::Analyzers::UselessNoise < Base
  def call
    score = @client.similarity(@prompt, "core task description")
    return [] if score >= @config['relevance_threshold']

    [{
      id: 'A1',
      level: :warn,
      message: "Average relevance #{score.round(2)} < threshold"
    }]
  end
end
```

## Key Benefits

- Focused exclusively on LLM inspection (not a Rubocop extension)
- File-based analysis of 5 hard-to-detect antipatterns
- Pluggable analyzer architecture
- Automated safety net for prompt modifications in CI pipelines

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
