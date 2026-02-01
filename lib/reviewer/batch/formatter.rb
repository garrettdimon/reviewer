# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Batch
    # Display logic for batch execution: summary, run preview, missing tools
    class Formatter
      include Output::Formatting

      def initialize(output)
        @output = output
        @printer = output.printer
      end

      def batch_summary(tool_count, seconds)
        @output.newline
        @printer.print(:success, CHECKMARK)
        @printer.print(:muted, " ~#{seconds.round(1)} seconds")
        @printer.print(:muted, " for #{tool_count} tools") if tool_count > 1
        @output.newline
      end

      def run_summary(entries)
        return if entries.empty?

        entries.each { |entry| print_run_entry(entry) }
        @output.newline
      end

      def missing_tools(tools)
        label = pluralize(tools.size, 'not installed', 'not installed')
        label = "#{tools.size} not installed:"
        @output.newline
        @printer.puts(:warning, label)
        tools.each do |tool|
          hint = tool.installable? ? tool.install_command : ''
          @printer.puts(:muted, "  #{tool.name.ljust(22)}#{hint}")
        end
        @output.newline
      end

      def no_failures_to_retry
        @printer.puts(:muted, 'No failures to retry')
      end

      def no_previous_run
        @printer.puts(:muted, 'No previous run found')
      end

      private

      def print_run_entry(entry)
        @printer.puts(:muted, entry[:name])
        entry[:files].each { |file| @printer.puts(:muted, "  #{file}") }
      end
    end
  end
end
