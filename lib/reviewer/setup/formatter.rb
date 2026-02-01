# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  module Setup
    # Display logic for the first-run setup flow
    class Formatter
      include Output::Formatting

      def initialize(output)
        @output = output
        @printer = output.printer
      end

      def first_run_greeting
        @output.newline
        @printer.puts(:bold, "It looks like you're setting up Reviewer for the first time on this project.")
        @output.newline
        @printer.puts(:muted, 'This will auto-detect your tools and generate a .reviewer.yml configuration file.')
        @output.newline
      end

      def first_run_skip
        @printer.puts(:muted, 'You can run `rvw init` any time to auto-detect and configure your tools.')
        @output.newline
      end

      def setup_already_exists(config_file)
        @output.newline
        @printer.puts(:bold, "Configuration already exists: #{config_file.basename}")
        @output.newline
        @printer.puts(:muted, 'Run `rvw doctor` for a diagnostic report.')
        @printer.puts(:muted, 'To regenerate, remove the file and run `rvw init` again.')
        @output.newline
      end

      def setup_no_tools_detected
        @output.newline
        @printer.puts(:bold, 'No supported tools detected.')
        @output.newline
        @printer.puts(:muted, 'Create .reviewer.yml manually:')
        @printer.puts(:muted, "  #{Setup::CONFIG_URL}")
        @output.newline
      end

      def setup_success(results)
        @output.newline
        @printer.puts(:success, 'Created .reviewer.yml')
        @output.newline
        @printer.puts(:bold, 'Detected tools:')
        results.each { |result| @printer.puts(:default, result.summary) }
        @output.newline
        @printer.puts(:muted, "Configure further:    #{Setup::CONFIG_URL}")
        @printer.puts(:muted, 'Run `rvw` to review your code.')
        @output.newline
      end
    end
  end
end
