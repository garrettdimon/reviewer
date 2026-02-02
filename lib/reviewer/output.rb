# frozen_string_literal: true

require 'io/console/size' # For determining console width/height

require_relative 'output/formatting'
require_relative 'output/printer'

module Reviewer
  # Console display infrastructure — primitives and delegation to domain formatters.
  # Domain-specific display logic lives in each concept's Formatter class.
  # Output delegates to them so existing callers continue to work during migration.
  class Output
    DEFAULT_CONSOLE_WIDTH = 120
    DIVIDER = '─'
    RAKE_ABORTED_TEXT = "rake aborted!\n"

    # Removes unhelpful rake exit status noise from stderr
    # @param text [String, nil] the stderr output to clean up
    # @return [String] the cleaned text with rake noise removed
    def self.scrub(text)
      text = text.to_s
      return '' if text.empty?

      text.include?(RAKE_ABORTED_TEXT) ? text.split(RAKE_ABORTED_TEXT).first : text
    end

    attr_reader :printer

    # Creates an instance of Output to print Reviewer activity and results to the console
    # @param printer [Printer] the low-level printer for styled terminal output
    #
    # @return [Output]
    def initialize(printer = Printer.new)
      @printer = printer
    end

    # === Primitives ===

    # Clears the terminal screen
    # @return [void]
    def clear = system('clear')

    # Prints a blank line
    # @return [void]
    def newline = printer.puts(:default, '')

    # Prints a horizontal rule spanning the console width
    # @return [void]
    def divider
      newline
      printer.print(:muted, DIVIDER * console_width)
    end

    # Prints an unformatted help message
    # @param message [String] the help text to display
    # @return [void]
    def help(message)
      printer.puts(:default, message)
    end

    # Writes raw output directly without formatting
    # @param value [String] the raw output to write
    # @return [void]
    def unfiltered(value)
      printer.write_raw(value)
    end

    # === Session display (delegates to Session::Formatter) ===

    # Displays warnings for keywords that don't match any tool or git scope
    # @param unrecognized [Array<String>] the unrecognized keyword strings
    # @param suggestions [Hash{String => String}] keyword => suggested correction
    # @return [void]
    def unrecognized_keywords(unrecognized, suggestions) = session_formatter.unrecognized_keywords(unrecognized, suggestions)

    # Displays a warning when no configured tools match the requested names or tags
    # @param requested [Array<String>] tool names or tags the user asked for
    # @param available [Array<String>] all configured tool keys
    # @return [void]
    def no_matching_tools(requested:, available:) = session_formatter.no_matching_tools(requested: requested, available: available)

    # Displays a warning when an unrecognized output format is requested
    # @param value [String] the invalid format name
    # @param known [Array<Symbol>] the valid format options
    # @return [void]
    def invalid_format(value, known) = session_formatter.invalid_format(value, known)

    # Displays a git-related error with context-appropriate messaging
    # @param message [String] the error message from the git command
    # @return [void]
    def git_error(message) = session_formatter.git_error(message)

    # === Doctor display (delegates to Doctor::Formatter) ===

    # Renders a full diagnostic report
    # @param report [Doctor::Report] the report to display
    # @return [void]
    def doctor_report(report) = doctor_formatter.print(report)

    # === Setup display (delegates to Setup::Formatter) ===

    # Displays the welcome message when Reviewer has no configuration file
    # @return [void]
    def first_run_greeting = setup_formatter.first_run_greeting

    # Displays a hint about `rvw init` when the user declines initial setup
    # @return [void]
    def first_run_skip = setup_formatter.first_run_skip

    # Displays a notice when `rvw init` is run but .reviewer.yml already exists
    # @param config_file [Pathname] the existing configuration file path
    # @return [void]
    def setup_already_exists(config_file) = setup_formatter.setup_already_exists(config_file)

    # Displays a message when auto-detection finds no supported tools in the project
    # @return [void]
    def setup_no_tools_detected = setup_formatter.setup_no_tools_detected

    # Displays the results of a successful setup with the detected tools
    # @param results [Array<Detector::Result>] the tools that were detected and configured
    # @return [void]
    def setup_success(results) = setup_formatter.setup_success(results)

    protected

    # Returns the current console width, falling back to a default
    # @return [Integer] the console width in columns
    def console_width
      return DEFAULT_CONSOLE_WIDTH if IO.console.nil?

      _height, width = IO.console.winsize

      width.positive? ? width : DEFAULT_CONSOLE_WIDTH
    end

    private

    def session_formatter = @session_formatter ||= Session::Formatter.new(self)
    def doctor_formatter = @doctor_formatter ||= Doctor::Formatter.new(self)
    def setup_formatter = @setup_formatter ||= Setup::Formatter.new(self)
  end
end
