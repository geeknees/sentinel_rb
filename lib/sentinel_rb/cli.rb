# frozen_string_literal: true

require "thor"
require_relative "analyzer"
require_relative "report"

module SentinelRb
  # Command Line Interface for SentinelRb
  class CLI < Thor
    desc "analyze", "Analyze prompt files for antipatterns"
    option :glob, type: :string, desc: "Glob pattern for files to analyze"
    option :files, type: :array, desc: "Specific files to analyze"
    option :config, type: :string, default: ".sentinel.yml", desc: "Configuration file path"
    option :format, type: :string, default: "table", desc: "Output format (table, json, detailed)"
    option :output, type: :string, desc: "Output file path (default: stdout)"
    option :analyzers, type: :array, desc: "Specific analyzers to run (e.g., A1,A2)"
    option :no_summary, type: :boolean, default: false, desc: "Skip summary output"
    option :no_color, type: :boolean, default: false, desc: "Disable colored output"
    option :quiet, type: :boolean, default: false, desc: "Suppress non-error output"
    option :verbose, type: :boolean, default: false, desc: "Enable verbose output"
    def analyze
      # Load configuration
      config = load_config(options[:config])
      analyzer = SentinelRb::Analyzer.new(config)

      # Determine files to analyze
      files_to_analyze = determine_files(options)
      error_exit("No files found to analyze. Use --glob or --files to specify files.") if files_to_analyze.empty?

      say("Analyzing #{files_to_analyze.length} files...") unless options[:quiet]

      # Run analysis
      results = files_to_analyze.map do |file|
        say("  Analyzing #{file}...") if options[:verbose]
        analyzer.analyze_file(file, analyzer_ids: options[:analyzers])
      end

      # Format and output results
      formatted_output = SentinelRb::Report::Formatter.format(
        results,
        format: options[:format],
        show_summary: !options[:no_summary],
        colorize: !options[:no_color] && $stdout.tty?
      )

      output_results(formatted_output, options[:output])

      # Exit with appropriate code
      summary = analyzer.summarize_results(results)
      exit_code = summary[:total_findings].positive? ? 1 : 0
      exit(exit_code)
    rescue StandardError => e
      error_exit("Analysis failed: #{e.message}")
    end

    desc "version", "Show SentinelRb version"
    def version
      say("SentinelRb #{SentinelRb::VERSION}")
    end

    desc "config", "Show current configuration"
    option :config, type: :string, default: ".sentinel.yml", desc: "Configuration file path"
    def config
      config = load_config(options[:config])
      say("Configuration loaded from: #{options[:config]}")
      say("")

      config.to_h.each do |key, value|
        say("#{key}: #{value}")
      end
    end

    desc "test_connection", "Test connection to LLM provider"
    option :config, type: :string, default: ".sentinel.yml", desc: "Configuration file path"
    def test_connection
      config = load_config(options[:config])
      client = SentinelRb::Client::Factory.create(config)

      say("Testing connection to #{config.provider}...")

      begin
        # Test with a simple analysis
        result = client.analyze_content("This is a test prompt for connection verification.")

        if result[:relevance_score]
          say("✅ Connection successful!")
          say("Test analysis score: #{result[:relevance_score].round(3)}")
        else
          error_exit("❌ Connection failed: No response received")
        end
      rescue StandardError => e
        error_exit("❌ Connection failed: #{e.message}")
      end
    end

    no_commands do
      private

      def load_config(config_path)
        if !File.exist?(config_path) && !options[:quiet]
          say("Configuration file #{config_path} not found, using defaults.", :yellow)
        end

        SentinelRb::Config.load(config_path)
      rescue StandardError => e
        error_exit("Failed to load configuration: #{e.message}")
      end

      def determine_files(options)
        files = []

        files.concat(options[:files]) if options[:files]

        files.concat(Dir.glob(options[:glob])) if options[:glob]

        # Default glob if no files specified
        if files.empty?
          default_patterns = [
            "prompts/**/*.{md,txt,json}",
            "**/*.prompt",
            "**/*.prompt.md"
          ]

          default_patterns.each do |pattern|
            found_files = Dir.glob(pattern)
            if found_files.any?
              files.concat(found_files)
              break
            end
          end
        end

        files.uniq.select { |f| File.file?(f) }
      end

      def output_results(content, output_file)
        if output_file
          File.write(output_file, content)
          say("Results written to #{output_file}") unless options[:quiet]
        else
          say(content)
        end
      end

      def error_exit(message)
        say("Error: #{message}", :red)
        exit(1)
      end
    end
  end
end
