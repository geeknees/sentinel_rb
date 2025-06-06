# SentinelRb Usage Guide

## Quick Start

### Installation
```bash
gem install sentinel_rb
```

### Basic Usage
```bash
sentinel --glob "prompts/**/*.{md,json}" --config .sentinel.yml
```

## Configuration

### Creating Configuration File
Create `.sentinel.yml` in your project root:

```yaml
# LLM Provider Configuration
provider: openai
model: gpt-4o-mini
api_key_env: OPENAI_API_KEY

# Analysis Thresholds
relevance_threshold: 0.55
divergence_threshold: 0.25

# Security Settings
dangerous_tools:
  - delete_file
  - transfer_funds
  - system_shutdown
  - exec_command

# File Processing
skip_patterns:
  - "**/.git/**"
  - "**/node_modules/**"
  - "**/tmp/**"

# Output Settings
output_format: table  # table, json, detailed
log_level: warn      # debug, info, warn, error
```

### Environment Variables
```bash
export OPENAI_API_KEY="your-api-key-here"
export ANTHROPIC_API_KEY="your-anthropic-key"  # if using Anthropic
```

## Command Line Interface

### Basic Commands
```bash
# Analyze specific files
sentinel --files prompt1.md prompt2.json

# Use glob patterns
sentinel --glob "prompts/**/*.md"

# Specify configuration
sentinel --config custom-config.yml --glob "**/*.prompt"

# Output formats
sentinel --format json --output results.json
sentinel --format table
sentinel --format detailed --output report.txt
```

### Advanced Options
```bash
# Parallel processing
sentinel --workers 4 --glob "**/*.md"

# Skip specific analyzers
sentinel --skip A1,A3 --glob "**/*.md"

# Run only specific analyzers
sentinel --only A2,A4 --glob "**/*.md"

# Verbose output
sentinel --verbose --glob "**/*.md"
```

## Integration Examples

### GitHub Actions
```yaml
name: Sentinel Prompt QA
on: [pull_request]

jobs:
  prompt-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
      - run: gem install sentinel_rb
      - name: Run Sentinel
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          sentinel --glob "prompts/**/*" --config .sentinel.yml --format table
```

### Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit
sentinel --glob "prompts/**/*.{md,json}" --config .sentinel.yml --format table
exit_code=$?
if [ $exit_code -ne 0 ]; then
  echo "Sentinel found issues in prompts. Please review and fix."
  exit 1
fi
```

### Ruby Integration
```ruby
require 'sentinel_rb'

# Programmatic usage
config = SentinelRb::Config.load('.sentinel.yml')
analyzer = SentinelRb::Analyzer.new(config)

results = analyzer.analyze_file('path/to/prompt.md')
results.each do |finding|
  puts "#{finding[:level]}: #{finding[:message]}"
end
```

## Analyzer-Specific Usage

### A1: Irrelevant Information
- **Purpose**: Detect noisy or off-topic content
- **Tuning**: Adjust `relevance_threshold` (0.0-1.0)
- **Example**: Flag prompts with marketing copy mixed with technical instructions

### A2: Misinformation Detection
- **Purpose**: Verify factual accuracy
- **Configuration**: Enable fact-checking API or RAG database
- **Example**: Detect outdated API documentation or incorrect technical claims

### A3: Few-shot Bias Order
- **Purpose**: Detect ordering bias in examples
- **Configuration**: Set `divergence_threshold` for KL divergence
- **Example**: Flag when examples are always positive-negative-positive pattern

### A4: Base Model Usage
- **Purpose**: Prevent base model usage in production
- **Configuration**: Automatically detects '-base' in model names
- **Example**: Flag `gpt-4-base` usage instead of `gpt-4`

### A5: Dangerous Tool Execution
- **Purpose**: Prevent auto-execution of dangerous tools
- **Configuration**: Customize `dangerous_tools` list
- **Example**: Flag tools that can delete files or transfer money

## Troubleshooting

### Common Issues

#### API Key Issues
```bash
# Check environment variable
echo $OPENAI_API_KEY

# Test API connectivity
sentinel --test-connection
```

#### File Permission Issues
```bash
# Check file permissions
ls -la prompts/

# Fix permissions
chmod 644 prompts/*.md
```

#### Configuration Issues
```bash
# Validate configuration
sentinel --validate-config .sentinel.yml

# Use default configuration
sentinel --no-config --glob "**/*.md"
```

### Performance Tuning

#### For Large Prompt Sets
```yaml
# .sentinel.yml
parallel_workers: 8
batch_size: 10
cache_responses: true
rate_limit: 100  # requests per minute
```

#### For CI/CD Optimization
```yaml
# Faster CI configuration
provider: openai
model: gpt-3.5-turbo  # Faster, cheaper model
cache_responses: true
skip_patterns:
  - "**/test/**"
  - "**/examples/**"
```

## Best Practices

### Prompt Organization
```
prompts/
├── system/           # System prompts
├── user/            # User interaction prompts
├── examples/        # Few-shot examples
└── templates/       # Reusable templates
```

### Team Workflow
1. **Development**: Use lenient thresholds for exploration
2. **Staging**: Apply production thresholds for validation
3. **Production**: Strict validation with CI gate checks
4. **Review**: Regular threshold adjustment based on findings

### Configuration Management
- Use different configs for different environments
- Version control your `.sentinel.yml`
- Document threshold choices and reasoning
- Regular review and updates of dangerous tools list
