# frozen_string_literal: true

module Reviewer
  class Report
    # Formats a Report for summary output to the console
    class Formatter
      include Output::Formatting

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
        style = status_style(result.success?)
        mark = status_mark(result.success?)
        output.printer.print(style, "#{mark} #{result.tool_name}")
        print_timing(result)
        print_details(result)
      end

      def print_timing(result)
        output.printer.print(:muted, "    #{format_duration(result.duration)}")
      end

      def print_details(result)
        detail = result.detail_summary
        return unless detail

        output.printer.print(:muted, "   #{detail}")
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
          print_truncated_output(result.stdout)
        end
      end

      def print_truncated_output(text)
        content = text.to_s.strip
        return if content.empty?

        lines = content.lines
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
    end
  end
end
