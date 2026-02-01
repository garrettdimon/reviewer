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
    def self.scrub(text)
      return '' if text.nil?

      text.include?(RAKE_ABORTED_TEXT) ? text.split(RAKE_ABORTED_TEXT).first : text
    end

    attr_reader :printer

    # Creates an instance of Output to print Reviewer activity and results to the console
    def initialize(printer = Printer.new)
      @printer = printer
    end

    # === Primitives ===

    def clear = system('clear')

    def newline = printer.puts(:default, '')

    def divider
      newline
      printer.print(:muted, DIVIDER * console_width)
    end

    def help(message)
      printer.puts(:default, message)
    end

    def unfiltered(value)
      return if value.nil? || value.strip.empty?

      printer.stream << value
    end

    # === Runner display (delegates to Runner::Formatter) ===

    def tool_summary(tool) = runner_formatter.tool_summary(tool)
    def current_command(command) = runner_formatter.current_command(command)
    def success(timer) = runner_formatter.success(timer)
    def skipped(reason = 'no matching files') = runner_formatter.skipped(reason)
    def failure(details, command: nil) = runner_formatter.failure(details, command: command)
    def unrecoverable(details) = runner_formatter.unrecoverable(details)
    def guidance(summary, details) = runner_formatter.guidance(summary, details)

    # === Batch display (delegates to Batch::Formatter) ===

    def batch_summary(tool_count, seconds) = batch_formatter.batch_summary(tool_count, seconds)
    def run_summary(entries) = batch_formatter.run_summary(entries)
    def missing_tools(tools) = batch_formatter.missing_tools(tools)
    def no_failures_to_retry = batch_formatter.no_failures_to_retry
    def no_previous_run = batch_formatter.no_previous_run

    # === Session display (delegates to Session::Formatter) ===

    def unrecognized_keywords(unrecognized, suggestions) = session_formatter.unrecognized_keywords(unrecognized, suggestions)
    def no_matching_tools(requested:, available:) = session_formatter.no_matching_tools(requested: requested, available: available)
    def invalid_format(value, known) = session_formatter.invalid_format(value, known)
    def git_error(message) = session_formatter.git_error(message)

    # === Doctor display (delegates to Doctor::Formatter) ===

    def doctor_report(report) = doctor_formatter.print(report)

    # === Setup display (delegates to Setup::Formatter) ===

    def first_run_greeting = setup_formatter.first_run_greeting
    def first_run_skip = setup_formatter.first_run_skip
    def setup_already_exists(config_file) = setup_formatter.setup_already_exists(config_file)
    def setup_no_tools_detected = setup_formatter.setup_no_tools_detected
    def setup_success(results) = setup_formatter.setup_success(results)

    protected

    def console_width
      return DEFAULT_CONSOLE_WIDTH if IO.console.nil?

      _height, width = IO.console.winsize

      width.positive? ? width : DEFAULT_CONSOLE_WIDTH
    end

    private

    def runner_formatter = @runner_formatter ||= Runner::Formatter.new(self)
    def batch_formatter = @batch_formatter ||= Batch::Formatter.new(self)
    def session_formatter = @session_formatter ||= Session::Formatter.new(self)
    def doctor_formatter = @doctor_formatter ||= Doctor::Formatter.new(self)
    def setup_formatter = @setup_formatter ||= Setup::Formatter.new(self)
  end
end
