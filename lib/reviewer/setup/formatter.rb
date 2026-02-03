# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  module Setup
    # Display logic for the first-run setup flow
    class Formatter
      include Output::Formatting

      attr_reader :output, :printer
      private :output, :printer

      # Creates a formatter for setup flow display
      # @param output [Output] the console output handler
      #
      # @return [Formatter]
      def initialize(output)
        @output = output
        @printer = output.printer
      end

      # Displays the welcome message when Reviewer has no configuration file
      #
      # @return [void]
      def first_run_greeting
        output.newline
        printer.puts(:bold, "It looks like you're setting up Reviewer for the first time on this project.")
        output.newline
        printer.puts(:muted, 'This will auto-detect your tools and generate a .reviewer.yml configuration file.')
        output.newline
      end

      # Displays a hint about `rvw init` when the user declines initial setup
      #
      # @return [void]
      def first_run_skip
        printer.puts(:muted, 'You can run `rvw init` any time to auto-detect and configure your tools.')
        output.newline
      end

      # Displays a notice when `rvw init` is run but .reviewer.yml already exists
      # @param config_file [Pathname] the existing configuration file path
      #
      # @return [void]
      def setup_already_exists(config_file)
        output.newline
        printer.puts(:bold, "Configuration already exists: #{config_file.basename}")
        output.newline
        printer.puts(:muted, 'Run `rvw doctor` for a diagnostic report.')
        printer.puts(:muted, 'To regenerate, remove the file and run `rvw init` again.')
        output.newline
      end

      # Displays a message when auto-detection finds no supported tools in the project
      #
      # @return [void]
      def setup_no_tools_detected
        output.newline
        printer.puts(:bold, 'No supported tools detected.')
        output.newline
        printer.puts(:muted, 'Create .reviewer.yml manually:')
        printer.puts(:muted, "  #{Setup::CONFIG_URL}")
        output.newline
      end

      # Displays the results of a successful setup with the detected tools
      # @param results [Array<Detector::Result>] the tools that were detected and configured
      #
      # @return [void]
      def setup_success(results)
        output.newline
        printer.puts(:success, 'Created .reviewer.yml')
        print_detected_tools(results)
        print_setup_footer
      end

      private

      def print_detected_tools(results)
        output.newline
        printer.puts(:bold, 'Detected tools:')
        results.each { |result| printer.puts(:default, result.summary) }
      end

      def print_setup_footer
        output.newline
        printer.puts(:muted, "Configure further:    #{Setup::CONFIG_URL}")
        printer.puts(:muted, 'Run `rvw` to review your code.')
        output.newline
      end
    end
  end
end
