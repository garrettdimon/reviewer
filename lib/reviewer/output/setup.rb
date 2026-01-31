# frozen_string_literal: true

module Reviewer
  class Output
    # Output methods for the `rvw init` setup flow.
    # All methods are public — they are called directly from Setup.run and Reviewer.
    module Setup
      # Prints guidance when .reviewer.yml is missing
      # @param file [Pathname] the expected path of the configuration file
      #
      # @return [void]
      def missing_configuration(file)
        newline
        printer.puts(:error, 'No configuration found')
        printer.puts(:muted, "Expected: ./#{file.basename}")
        newline
        printer.puts(:bold, 'To get started:')
        printer.puts(:default, '  rvw init              Auto-detect tools and generate .reviewer.yml')
        printer.puts(:muted, "  Create manually       #{Reviewer::Setup::CONFIG_URL}")
        newline
      end

      # Prints a message when .reviewer.yml already exists
      # @param config_file [Pathname] the existing config file path
      #
      # @return [void]
      def setup_already_exists(config_file)
        newline
        printer.puts(:bold, "Configuration already exists: #{config_file.basename}")
        newline
        printer.puts(:muted, 'Run `rvw doctor` for a diagnostic report.')
        printer.puts(:muted, 'To regenerate, remove the file and run `rvw init` again.')
        newline
      end

      # Prints a message when no tools could be detected
      #
      # @return [void]
      def setup_no_tools_detected
        newline
        printer.puts(:bold, 'No supported tools detected.')
        newline
        printer.puts(:muted, 'Create .reviewer.yml manually:')
        printer.puts(:muted, "  #{Reviewer::Setup::CONFIG_URL}")
        newline
      end

      # Prints a success message after generating .reviewer.yml
      # @param results [Array<Reviewer::Setup::Detector::Result>] detected tools with evidence
      #
      # @return [void]
      def setup_success(results)
        newline
        printer.puts(:success, 'Created .reviewer.yml')
        newline
        printer.puts(:bold, 'Detected tools:')
        results.each { |result| printer.puts(:default, result.summary) }
        newline
        printer.puts(:muted, "Configure further:    #{Reviewer::Setup::CONFIG_URL}")
        printer.puts(:muted, 'Run `rvw` to review your code.')
        newline
      end
    end
  end
end
