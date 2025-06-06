# frozen_string_literal: true

require_relative "lib/sentinel_rb/version"

Gem::Specification.new do |spec|
  spec.name = "sentinel_rb"
  spec.version = SentinelRb::VERSION
  spec.authors = ["Masumi Kawasaki"]
  spec.email = ["geeknees@gmail.com"]

  spec.summary = "LLM-driven prompt inspection to detect common antipatterns in prompts"
  spec.description = "SentinelRb provides automated analysis of AI prompts to identify and flag common antipatterns like irrelevant information, misinformation, bias, and dangerous instructions. Uses LLM-based scoring combined with heuristic pattern matching for comprehensive prompt quality assessment."
  spec.homepage = "https://github.com/geeknees/sentinel_rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/geeknees/sentinel_rb"
  spec.metadata["changelog_uri"] = "https://github.com/geeknees/sentinel_rb/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies for SentinelRb
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "ruby-openai", "~> 7.0"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "yaml", "~> 0.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
