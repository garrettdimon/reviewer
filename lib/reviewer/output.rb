# frozen_string_literal: true

require 'io/console/size' # For determining console width/height

require_relative 'output/printer'
require_relative 'output/token'

module Reviewer
  # Friendly API for printing nicely-formatted output to the console
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

    # Clears the console screen
    #
    # @return [Boolean, nil] result of system call
    def clear = system('clear')

    # Prints an empty line
    #
    # @return [void]
    def newline = printer.puts(:default, '')

    # Prints a horizontal divider line
    #
    # @return [void]
    def divider
      newline
      printer.print(:muted, DIVIDER * console_width)
    end

    # Prints plain text to the console
    # @param message [String] the text to write to the console
    #
    # @return [void]
    def help(message)
      printer.puts(:default, message)
    end

    # Prints a summary of the total time and results for a batch run. If multiple tools, it will
    #  show the total tool count
    # @param tool_count [Integer] the number of commands run in the batch
    # @param seconds [Float] the total number of seconds the batch ran in realtime
    #
    # @return [void]
    def batch_summary(tool_count, seconds)
      printer.print(:bold, "~#{seconds.round(1)} seconds")
      printer.print(:muted, " for #{tool_count} tools") if tool_count > 1
      newline
    end

    # Print a tool summary using the name and description. Used before running a command to help
    #   identify which tool is running at any given moment.
    # @param tool [Tool] the tool to identify and describe
    #
    # @return [void]
    def tool_summary(tool)
      printer.print(:bold, tool.name)
      printer.puts(:muted, " #{tool.description}")
    end

    # Prints the text of a command to the console to help proactively expose potentials issues with
    #   syntax if Reviewer translated thte provided options in an unexpected way
    # @param command [String, Command] the command to identify on the console
    #
    # @return [void] [description]
    def current_command(command)
      printer.puts(:bold, 'Now Running:')
      printer.puts(:default, String(command))
    end

    # Prints a success message with timing information
    # @param timer [Shell::Timer] the timer with execution times
    #
    # @return [void]
    def success(timer)
      printer.print(:success, 'Success')
      printer.print(:success_light, " #{timer.total_seconds}s")
      printer.print(:warning_light, " (#{timer.prep_percent}% prep ~#{timer.prep_seconds}s)") if timer.prepped?
      newline
      newline
    end

    # Prints a skipped message with the reason
    # @param reason [String] why the tool was skipped
    #
    # @return [void]
    def skipped(reason = 'no matching files')
      printer.print(:muted, 'Skipped')
      printer.puts(:muted, " (#{reason})")
      newline
    end

    # Prints a failure message with details and optionally the failed command
    # @param details [String] the failure details
    # @param command [String, Command, nil] the command that failed
    #
    # @return [void]
    def failure(details, command: nil)
      printer.print(:failure, 'Failure')
      printer.puts(:muted, " #{details}")

      return if command.nil?

      newline
      printer.puts(:bold, 'Failed Command:')
      printer.puts(:muted, String(command))
    end

    # Prints an unrecoverable error message
    # @param details [String] the error details to display
    #
    # @return [void]
    def unrecoverable(details)
      printer.puts(:error, 'Unrecoverable Error:')
      printer.puts(:muted, details)
    end

    # Prints guidance information to help users resolve issues
    # @param summary [String] the bold summary line
    # @param details [String, nil] the detailed guidance text
    #
    # @return [void]
    def guidance(summary, details)
      return if details.nil?

      newline
      printer.puts(:bold, summary)
      printer.puts(:muted, details)
    end

    # Outputs raw content directly to the stream without styling
    # @param value [String, nil] the content to output
    #
    # @return [void]
    def unfiltered(value)
      return if value.nil? || value.strip.empty?

      printer.stream << value
    end

    protected

    def console_width
      return DEFAULT_CONSOLE_WIDTH if IO.console.nil?

      _height, width = IO.console.winsize

      width
    end
  end
end
