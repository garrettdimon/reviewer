# frozen_string_literal: true

require 'io/console' # For determining console width/height

require_relative 'output/printer'
require_relative 'output/scrubber'

module Reviewer
  # Friendly API for printing nicely-formatted output to the console
  class Output
    DIVIDER = '·'

    attr_reader :printer

    # Creates an instance of Output to print Reviewer activity and results to the console
    def initialize(printer = Printer.new)
      @printer = printer
    end

    def clear
      system('clear')
    end

    def newline
      printer.puts(:default, '')
    end

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
      printer.puts(:muted, " for #{tool_count} tools") if tool_count > 1
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

    def success(timer)
      printer.print(:success, 'Success')
      printer.print(:success_light, " #{timer.total_seconds}s")
      printer.print(:warning_light, " (#{timer.prep_percent}% prep ~#{timer.prep_seconds}s)") if timer.prepped?
      newline
      newline
    end

    def failure(details, command: nil)
      printer.print(:failure, 'Failure')
      printer.puts(:muted, " #{details}")

      return if command.nil?

      newline
      printer.puts(:bold, 'Failed Command:')
      printer.puts(:muted, String(command))
    end

    def unrecoverable(details)
      printer.puts(:error, 'Unrecoverable Error:')
      printer.puts(:muted, details)
    end

    def guidance(summary, details)
      return if details.nil?

      newline
      printer.puts(:bold, summary)
      printer.puts(:muted, details)
    end

    def unfiltered(value)
      return if value.nil? || value.strip.empty?

      printer.stream << value
    end

    protected

    def console_width
      _height, width = IO.console.winsize

      width
    end
  end
end
