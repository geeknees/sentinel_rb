# SentinelRb Architecture

## Overview

SentinelRb is a Ruby gem that provides LLM-driven prompt inspection to automatically detect common antipatterns in prompts that are difficult to catch with static analysis.

## Core Components

### 1. Configuration Management
- **File**: `.sentinel.yml`
- **Purpose**: Centralized configuration for thresholds, providers, and dangerous tools
- **Key Settings**:
  - `provider`: LLM provider (openai, anthropic, etc.)
  - `model`: Specific model to use
  - `relevance_threshold`: Threshold for relevance scoring (default: 0.55)
  - `divergence_threshold`: Threshold for KL divergence detection (default: 0.25)
  - `dangerous_tools`: List of tools considered dangerous for auto-execution

### 2. LLM Client Layer
- **Purpose**: Abstraction layer for different LLM providers
- **Supported Providers**:
  - OpenAI GPT models
  - Anthropic Claude models
  - Custom API endpoints
- **Key Methods**:
  - `similarity(prompt, reference)`: Calculate semantic similarity
  - `fact_check(statement)`: Verify factual accuracy
  - `analyze_content(prompt)`: General content analysis

### 3. Analyzer System

#### Base Analyzer
```ruby
class SentinelRb::Analyzers::Base
  def initialize(prompt, config, client)
    @prompt = prompt
    @config = config
    @client = client
  end

  def call
    # Returns array of findings: [{id:, level:, message:}, ...]
  end
end
```

#### Implemented Analyzers

##### A1: Irrelevant Information Detector
- **Purpose**: Detect prompts containing irrelevant or noisy information
- **Method**: Uses LLM to generate relevance scores
- **Threshold**: Configurable via `relevance_threshold`
- **Output**: Warning when average relevance score is below threshold

##### A2: Misinformation & Logical Contradictions
- **Purpose**: Verify factual accuracy and logical consistency
- **Method**: RAG-based knowledge base lookup or fact-checking API
- **Detection**: Cross-references statements against reliable sources
- **Output**: Error level for confirmed misinformation

##### A3: Few-shot Bias Order Detection
- **Purpose**: Detect ordering bias in few-shot examples
- **Method**: Compares example order with canonical examples in YAML
- **Metric**: KL Divergence calculation
- **Threshold**: Configurable via `divergence_threshold`

##### A4: Base Model Usage Detection
- **Purpose**: Flag usage of base models instead of instruction-tuned models
- **Method**: String matching for '-base' in model names
- **Output**: Immediate warning for any base model usage

##### A5: Dangerous Automatic Tool Execution
- **Purpose**: Detect dangerous tools marked for automatic execution
- **Method**: JSON parsing to find `dangerous:true && auto_execute:true`
- **Configuration**: Uses `dangerous_tools` list from config
- **Output**: Critical level warning for security risks

### 4. Reporting System
- **Formats**: Table, JSON, detailed reports
- **Integration**: Designed for CI/CD pipeline integration
- **Output Levels**: info, warn, error, critical

## File Processing Pipeline

1. **Discovery**: Glob pattern matching to find prompt files
2. **Loading**: Read and parse prompt files (MD, JSON, YAML support)
3. **Analysis**: Run all enabled analyzers on each prompt
4. **Aggregation**: Collect results from all analyzers
5. **Reporting**: Format and output results in specified format

## Extension Points

### Custom Analyzers
Developers can create custom analyzers by:
1. Inheriting from `SentinelRb::Analyzers::Base`
2. Implementing the `call` method
3. Registering the analyzer in the configuration

### Custom LLM Providers
Support for additional LLM providers can be added by:
1. Implementing the client interface
2. Adding provider-specific configuration
3. Registering the provider in the client factory

## Security Considerations

- API keys are loaded from environment variables
- Dangerous tool detection prevents accidental auto-execution
- No prompt data is persisted by default
- Configurable rate limiting for API calls

## Performance Optimization

- Parallel processing of multiple prompt files
- Caching of LLM responses for repeated analysis
- Configurable batch processing for large prompt sets
- Optional skip patterns for excluding files

## CI/CD Integration

### GitHub Actions
Pre-built workflow templates for:
- Pull request validation
- Scheduled prompt auditing
- Release gate checks

### Configuration Examples
- Development environment setup
- Production deployment settings
- Team-specific threshold configurations