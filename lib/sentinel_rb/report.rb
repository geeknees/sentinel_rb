# frozen_string_literal: true

module SentinelRb
  module Report
    # Formats analysis results for different output types
    class Formatter
      def self.format(results, format: :table, **options)
        case format.to_sym
        when :table
          TableFormatter.new.format(results, **options)
        when :json
          JsonFormatter.new.format(results, **options)
        when :detailed
          DetailedFormatter.new.format(results, **options)
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end
    end

    # Base class for result formatters
    class BaseFormatter
      def format(results, **options)
        raise NotImplementedError
      end

      protected

      def level_symbol(level)
        case level.to_sym
        when :critical then "🚨"
        when :error then "❌"
        when :warn then "⚠️ "
        when :info then "ℹ️ "
        else "  "
        end
      end

      def level_color_code(level)
        case level.to_sym
        when :critical then "\e[91m" # bright red
        when :error then "\e[31m"    # red
        when :warn then "\e[33m"     # yellow
        when :info then "\e[36m"     # cyan
        else "\e[0m"                 # reset
        end
      end

      def reset_color
        "\e[0m"
      end
    end

    # Table formatter for terminal output
    class TableFormatter < BaseFormatter
      def format(results, show_summary: true, colorize: true, **options)
        output = []
        
        if show_summary
          summary = SentinelRb::Analyzer.new.summarize_results(results)
          output << format_summary(summary, colorize)
          output << ""
        end

        results.each do |result|
          next if result[:findings].nil? || result[:findings].empty?
          
          output << format_file_header(result[:file], colorize)
          
          result[:findings].each do |finding|
            output << format_finding(finding, colorize)
          end
          
          output << ""
        end

        output.join("\n")
      end

      private

      def format_summary(summary, colorize)
        lines = ["=" * 50]
        lines << "SentinelRb Analysis Summary"
        lines << "=" * 50
        lines << "Files analyzed: #{summary[:total_files]}"
        lines << "Files with issues: #{summary[:files_with_issues]}"
        lines << "Total findings: #{summary[:total_findings]}"
        lines << "Pass rate: #{summary[:pass_rate]}%"
        
        if summary[:findings_by_level].any?
          lines << ""
          lines << "Findings by level:"
          summary[:findings_by_level].each do |level, count|
            symbol = level_symbol(level)
            color = colorize ? level_color_code(level) : ""
            reset = colorize ? reset_color : ""
            lines << "  #{color}#{symbol} #{level.to_s.capitalize}: #{count}#{reset}"
          end
        end
        
        lines.join("\n")
      end

      def format_file_header(file, colorize)
        if colorize
          "\e[1m📄 #{file}\e[0m"
        else
          "📄 #{file}"
        end
      end

      def format_finding(finding, colorize)
        symbol = level_symbol(finding[:level])
        color = colorize ? level_color_code(finding[:level]) : ""
        reset = colorize ? reset_color : ""
        
        "  #{color}#{symbol} [#{finding[:id]}] #{finding[:message]}#{reset}"
      end
    end

    # JSON formatter for programmatic consumption
    class JsonFormatter < BaseFormatter
      def format(results, pretty: true, **options)
        require "json"
        
        output = {
          timestamp: Time.now.iso8601,
          summary: SentinelRb::Analyzer.new.summarize_results(results),
          results: results
        }
        
        if pretty
          JSON.pretty_generate(output)
        else
          JSON.generate(output)
        end
      end
    end

    # Detailed formatter with full finding information
    class DetailedFormatter < BaseFormatter
      def format(results, **options)
        output = []
        
        summary = SentinelRb::Analyzer.new.summarize_results(results)
        output << format_detailed_summary(summary)
        output << ""

        results.each do |result|
          output << format_detailed_file(result)
        end

        output.join("\n")
      end

      private

      def format_detailed_summary(summary)
        lines = ["SentinelRb Detailed Analysis Report"]
        lines << "Generated at: #{Time.now}"
        lines << "=" * 60
        lines << ""
        lines << "Summary:"
        lines << "  Total files analyzed: #{summary[:total_files]}"
        lines << "  Files with issues: #{summary[:files_with_issues]}"
        lines << "  Total findings: #{summary[:total_findings]}"
        lines << "  Overall pass rate: #{summary[:pass_rate]}%"
        lines << ""
        
        if summary[:findings_by_level].any?
          lines << "Findings breakdown:"
          summary[:findings_by_level].each do |level, count|
            lines << "  #{level.to_s.capitalize}: #{count}"
          end
          lines << ""
        end

        lines.join("\n")
      end

      def format_detailed_file(result)
        lines = []
        lines << "-" * 60
        lines << "File: #{result[:file]}"
        
        if result[:error]
          lines << "Error: #{result[:error]}"
          lines << ""
          return lines.join("\n")
        end

        lines << "Size: #{result[:size]} characters"
        lines << "Analyzed at: #{result[:analyzed_at]}"
        lines << ""

        if result[:findings].nil? || result[:findings].empty?
          lines << "✅ No issues found"
        else
          lines << "Issues found: #{result[:findings].length}"
          lines << ""
          
          result[:findings].each_with_index do |finding, index|
            lines << "Finding #{index + 1}:"
            lines << "  ID: #{finding[:id]}"
            lines << "  Level: #{finding[:level]}"
            lines << "  Message: #{finding[:message]}"
            
            if finding[:details] && finding[:details].any?
              lines << "  Details:"
              finding[:details].each do |key, value|
                lines << "    #{key}: #{value}"
              end
            end
            
            lines << ""
          end
        end

        lines.join("\n")
      end
    end
  end
end
