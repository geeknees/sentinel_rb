# SentinelRb

SentinelRb is an LLM-driven prompt inspector designed to automatically detect common antipatterns in prompts that are difficult to catch with static analysis.

## Overview

SentinelRb analyzes prompt files to detect five key antipatterns using OpenAI, RAG, and metadata:

| ID | Target | Detection Logic |
|----|--------|-----------------|
| A1 | Irrelevant Information | Uses LLM to generate relevance scores; flags prompts with avg_score < threshold |
| A2 | Misinformation & Logical Contradictions | Verifies facts using RAG knowledge base or fact-checking API |
| A3 | Few-shot Bias Order | Compares with canonical examples in YAML; warns when KL Divergence exceeds threshold |
| A4 | Base Model Usage | Immediately flags when chat request includes '-base' in model name |
| A5 | Dangerous Automatic Tool Execution | Detects JSON Actions with `dangerous:true && auto_execute:true` |

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
- OpenAI API key or other supported LLM provider credentials

## Usage

### Basic Usage

Run SentinelRb on your prompt files:

```bash
sentinel --glob "prompts/**/*.{md,json}" --config .sentinel.yml
```

### Configuration

Create a `.sentinel.yml` file in your project root:

```yaml
provider: openai
model: gpt-4o-mini
relevance_threshold: 0.55
divergence_threshold: 0.25
dangerous_tools:
  - delete_file
  - transfer_funds
```

### Developer Workflow

1. Place prompt templates in a `prompts/` directory
2. Create a pull request
3. GitHub Actions runs sentinel checks
4. CI fails if any analyzer generates warnings
5. Review the detailed Sentinel Report (table/JSON format)

### GitHub Actions Integration

```yaml
name: Sentinel Prompt QA
on: [pull_request]

jobs:
  prompt-check:
    runs-on: ubuntu-latest
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
