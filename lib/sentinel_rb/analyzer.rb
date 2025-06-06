# frozen_string_literal: true

require_relative "config"
require_relative "client"
require_relative "analyzers/irrelevant_info"
require_relative "analyzers/misinformation"
require_relative "analyzers/few_shot_bias"

module SentinelRb
  # Main analyzer engine that coordinates prompt analysis
  class Analyzer
    ANALYZERS = {
      "A1" => Analyzers::IrrelevantInfo,
      "A2" => Analyzers::Misinformation,
      "A3" => Analyzers::FewShotBias
    }.freeze

    def initialize(config = nil)
      @config = config || Config.load
      @client = Client::Factory.create(@config)
    end

    # Analyze a single prompt string
    # @param prompt [String] The prompt text to analyze
    # @param analyzer_ids [Array<String>] Specific analyzers to run (default: all)
    # @return [Array<Hash>] Array of findings
    def analyze_prompt(prompt, analyzer_ids: nil)
      return [] if prompt.nil? || prompt.strip.empty?

      analyzers_to_run = determine_analyzers(analyzer_ids)
      findings = []

      analyzers_to_run.each do |analyzer_class|
        begin
          analyzer = analyzer_class.new(prompt, @config, @client)
          findings.concat(analyzer.call)
        rescue StandardError => e
          # Log error but continue with other analyzers
          findings << {
            id: "ERROR",
            level: :error,
            message: "Analyzer #{analyzer_class.name} failed: #{e.message}",
            details: { error_class: e.class.name, backtrace: e.backtrace.first(3) }
          }
        end
      end

      findings
    end

    # Analyze a file containing prompt content
    # @param file_path [String] Path to the file to analyze
    # @param analyzer_ids [Array<String>] Specific analyzers to run (default: all)
    # @return [Hash] Analysis results with file info and findings
    def analyze_file(file_path, analyzer_ids: nil)
      unless File.exist?(file_path)
        return {
          file: file_path,
          error: "File not found",
          findings: []
        }
      end

      begin
        content = File.read(file_path, encoding: "UTF-8")
        puts "Debug: File size: #{content.length}, Content preview: #{content[0..100].inspect}" if ENV['DEBUG']
        findings = analyze_prompt(content, analyzer_ids: analyzer_ids)

        {
          file: file_path,
          size: content.length,
          findings: findings,
          analyzed_at: Time.now
        }
      rescue StandardError => e
        {
          file: file_path,
          error: "Failed to read or analyze file: #{e.message}",
          findings: []
        }
      end
    end

    # Analyze multiple files matching a glob pattern
    # @param pattern [String] Glob pattern for files to analyze
    # @param analyzer_ids [Array<String>] Specific analyzers to run (default: all)
    # @return [Array<Hash>] Array of file analysis results
    def analyze_files(pattern, analyzer_ids: nil)
      files = Dir.glob(pattern).reject { |f| should_skip_file?(f) }
      
      files.map do |file|
        analyze_file(file, analyzer_ids: analyzer_ids)
      end
    end

    # Get summary statistics for analysis results
    # @param results [Array<Hash>] Results from analyze_files
    # @return [Hash] Summary statistics
    def summarize_results(results)
      total_files = results.length
      files_with_issues = results.count { |r| r[:findings]&.any? }
      total_findings = results.sum { |r| r[:findings]&.length || 0 }

      findings_by_level = results
        .flat_map { |r| r[:findings] || [] }
        .group_by { |f| f[:level] }
        .transform_values(&:count)

      {
        total_files: total_files,
        files_with_issues: files_with_issues,
        total_findings: total_findings,
        findings_by_level: findings_by_level,
        pass_rate: total_files > 0 ? ((total_files - files_with_issues).to_f / total_files * 100).round(1) : 100.0
      }
    end

    private

    def determine_analyzers(analyzer_ids)
      if analyzer_ids.nil? || analyzer_ids.empty?
        ANALYZERS.values
      else
        analyzer_ids.map do |id|
          ANALYZERS[id] or raise ArgumentError, "Unknown analyzer: #{id}"
        end
      end
    end

    def should_skip_file?(file_path)
      skip_patterns = @config["skip_patterns"] || []
      
      skip_patterns.any? do |pattern|
        File.fnmatch(pattern, file_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
      end
    end
  end
end
