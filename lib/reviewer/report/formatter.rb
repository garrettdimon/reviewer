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
        @name_width = 0
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
        @name_width = max_name_width
        report.results.each { |result| print_tool_line(result) }
      end

      def print_tool_line(result)
        if result.missing?
          print_unrun_tool(result, style: :warning, reason: 'not installed')
        elsif result.skipped?
          print_unrun_tool(result, style: :muted, reason: 'no matching files')
        elsif result.not_run?
          print_unrun_tool(result, style: :muted, reason: 'stopped after failure')
        else
          print_executed_tool(result)
        end

        output.newline
      end

      # A tool that was selected but did not run is neither a pass nor a failure, so it gets no
      # status mark or timing. The reason explains whether the tool was skipped, missing, or stopped.
      def print_unrun_tool(result, style:, reason:)
        output.printer.print(style, "- #{result.tool_name.ljust(@name_width)}")
        output.printer.print(:muted, "    #{reason}")
      end

      def print_executed_tool(result)
        style = status_style(result.success?)
        mark = status_mark(result.success?)
        output.printer.print(style, "#{mark} #{result.tool_name.ljust(@name_width)}")
        print_timing(result)
        print_details(result)
      end

      def print_timing(result)
        output.printer.print(:muted, "    #{format_duration(result.duration).rjust(6)}")
      end

      def max_name_width
        report.results.map { |result| result.tool_name.length }.max || 0
      end

      def print_details(result)
        detail = result.detail_summary
        return unless detail

        output.printer.print(:muted, "   #{detail}")
      end

      def print_summary
        print_failure_summary unless report.success?
        print_result_summary
      end

      # "All passed" is reserved for reports containing only passed results. Other reports list
      # every nonzero state count so the totals account for every selected runnable tool.
      # :reek:FeatureEnvy -- formats Report's state counts for display
      # :reek:TooManyStatements -- one linear summary line with optional state counts
      def print_result_summary # rubocop:disable Metrics/AbcSize
        printer = output.printer
        counts = report.summary
        state_counts = counts.filter_map do |state, count|
          "#{count} #{state}" unless %i[total duration].include?(state) || count.zero?
        end

        all_passed = counts[:passed] == counts[:total]
        style = report.success? ? :success : :failure
        printer.print(style, all_passed ? 'All passed' : state_counts.join(', '))
        printer.puts(:muted, " (#{format_duration(report.duration)})")
      end

      def print_failure_summary
        failed_results = report.results.select(&:failed?)

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
