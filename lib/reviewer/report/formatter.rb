# frozen_string_literal: true

module Reviewer
  class Report
    # Formats a Report for summary output to the console
    class Formatter
      CHECKMARK = '✓'
      XMARK = '✗'

      attr_reader :report, :output

      # Creates a formatter for displaying a report
      # @param report [Report] the report to format
      # @param output [Output] the output handler for console display
      #
      # @return [Formatter] a formatter instance
      def initialize(report, output: Output.new)
        @report = report
        @output = output
      end

      # Prints the formatted report to the console
      #
      # @return [void]
      def print
        if report.results.empty?
          output.printer.puts(:muted, 'No tools to run')
          return
        end

        print_tool_lines
        output.newline
        print_summary
      end

      private

      def print_tool_lines
        report.results.each { |result| print_tool_line(result) }
      end

      def print_tool_line(result)
        if result.missing?
          print_missing_tool(result)
        else
          print_executed_tool(result)
        end

        output.newline
      end

      def print_missing_tool(result)
        output.printer.print(:warning, "- #{result.tool_name}")
        output.printer.print(:muted, '    not installed')
      end

      def print_executed_tool(result)
        style = result.success? ? :success : :failure
        mark = result.success? ? CHECKMARK : XMARK
        output.printer.print(style, "#{mark} #{result.tool_name}")
        print_timing(result)
        print_details(result)
      end

      def print_timing(result)
        output.printer.print(:muted, "    #{format_duration(result.duration)}")
      end

      def print_details(result)
        detail = extract_detail(result)
        return if detail.nil?

        output.printer.print(:muted, "   #{detail}")
      end

      def extract_detail(result)
        return extract_test_count(result.stdout) if result.tool_key == :tests
        return extract_offense_count(result.stdout) if result.tool_key == :rubocop

        nil
      end

      def extract_test_count(stdout)
        return nil if stdout.nil?

        match = stdout.match(/(\d+)\s+tests?/i)
        match ? "#{match[1]} tests" : nil
      end

      def extract_offense_count(stdout)
        return nil if stdout.nil?

        match = stdout.match(/(\d+)\s+offenses?/i)
        match ? "#{match[1]} offenses" : nil
      end

      def print_summary
        if report.success?
          print_success_summary
        else
          print_failure_summary
        end
      end

      def print_success_summary
        output.printer.print(:success, 'All passed')
        output.printer.puts(:muted, " (#{format_duration(report.duration)})")
      end

      def print_failure_summary
        failed_results = report.results.reject(&:success?).reject(&:missing?)

        failed_results.each do |result|
          output.newline
          output.printer.puts(:failure, "#{result.tool_name}:")
          print_failure_output(result)
        end
      end

      def print_failure_output(result)
        stdout = result.stdout
        return if stdout.nil? || stdout.strip.empty?

        lines = stdout.strip.lines
        print_lines(lines.first(10))
        print_truncation_notice(lines.size - 10)
      end

      def print_lines(lines)
        lines.each { |line| output.printer.puts(:default, line.chomp) }
      end

      def print_truncation_notice(remaining)
        return unless remaining.positive?

        output.printer.puts(:muted, "[#{remaining} more lines]")
      end

      def format_duration(seconds)
        return '0.0s' if seconds.nil?

        "#{seconds.round(2)}s"
      end
    end
  end
end
