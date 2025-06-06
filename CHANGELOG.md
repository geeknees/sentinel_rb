# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-06-07

### Added
- Initial release of SentinelRb
- LLM-driven prompt inspection for 5 key antipatterns:
  - A1: Irrelevant Information detection
  - A2: Misinformation & Logical Contradictions detection
  - A3: Few-shot Bias detection
  - A4: Base Model Usage (jailbreak attempts) detection
  - A5: Dangerous Tools detection
- CLI interface with multiple output formats (table, JSON, detailed)
- Library API for programmatic usage
- Configuration system via .sentinel.yml
- Mock mode for testing without API keys
- OpenAI integration with gpt-4o-mini model support
- Comprehensive test suite
- Documentation and usage examples

### Features
- Configurable thresholds for each analyzer
- Multiple file analysis with glob patterns
- Pluggable analyzer architecture
- CI/CD integration support
- Pattern-based and LLM-based detection methods

[0.1.0]: https://github.com/geeknees/sentinel_rb/releases/tag/v0.1.0
