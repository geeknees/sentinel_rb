# SentinelRb Agent Guide

## Overview

SentinelRb is an LLM-driven prompt inspector designed to automatically detect common antipatterns in prompts that are difficult to catch with static analysis. This tool helps developers maintain high-quality prompts by identifying issues that could negatively impact LLM performance.

## Core Purpose

SentinelRb analyzes prompt files to detect five key antipatterns using OpenAI, RAG, and metadata analysis:

- **A1: Irrelevant Information** - Detects prompts containing noisy or off-topic content
- **A2: Misinformation & Logical Contradictions** - Verifies factual accuracy using RAG knowledge base
- **A3: Few-shot Bias Order** - Identifies ordering bias in few-shot examples
- **A4: Base Model Usage** - Flags usage of base models instead of instruction-tuned models
- **A5: Dangerous Automatic Tool Execution** - Prevents auto-execution of dangerous tools

## Quick Reference

### Installation & Basic Usage
```bash
gem install sentinel_rb
sentinel --glob "prompts/**/*.{md,json}" --config .sentinel.yml
```

### Key Configuration
```yaml
provider: openai
model: gpt-4o-mini
relevance_threshold: 0.55
divergence_threshold: 0.25
```

## Detailed Documentation

For comprehensive information about SentinelRb, please refer to the following documentation:

### System Architecture
- **File**: `/docs/architecture.md`
- **Content**: Detailed technical architecture, component descriptions, analyzer implementations, and extension points

### Usage Guide
- **File**: `/docs/usage.md`
- **Content**: Complete usage instructions, configuration options, CLI commands, integration examples, and troubleshooting

### Development Guide
- **File**: `/docs/development.md`
- **Content**: Development setup, contributing guidelines, adding new analyzers, testing procedures, and release process

## Key Features for Agents

### Automated Analysis
- File-based prompt analysis
- Configurable thresholds and detection rules
- Multiple output formats (table, JSON, detailed)

### CI/CD Integration
- GitHub Actions workflow templates
- Pre-commit hooks
- Automated quality gates

### Extensibility
- Pluggable analyzer architecture
- Custom LLM provider support
- Configurable rule sets

### Security Focus
- Dangerous tool detection
- API key management
- No persistent data storage

## Agent-Specific Considerations

When working with SentinelRb in an agent context:

1. **Configuration Management**: Use environment-specific configurations for different deployment stages
2. **Rate Limiting**: Configure appropriate API rate limits to avoid quota exhaustion
3. **Error Handling**: Implement robust error handling for API failures and network issues
4. **Caching**: Enable response caching for improved performance with repeated analyses
5. **Monitoring**: Set up monitoring for analysis results and system health

## Getting Help

- **Documentation**: Check `/docs/` directory for detailed guides
- **Issues**: Report bugs and feature requests via GitHub issues
- **Examples**: See usage examples in the main README.md file

For technical implementation details, architectural decisions, and development procedures, always refer to the comprehensive documentation in the `/docs` directory.