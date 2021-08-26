# frozen_string_literal: true

require 'io/console' # For determining console width/height

module Reviewer
  # Friendly API for printing nicely-formatted output to the console
  class Output
    COLORS = {
      default: 39,
      red: 31,
      green: 32,
      yellow: 33,
      gray: 37
    }.freeze

    WEIGHTS = {
      default: 0,
      bold: 1,
      light: 2
    }.freeze

    DIVIDER = '·'

    attr_reader :stream

    # Creates an instance of Output to print Reviewer activity and results to the console
    def initialize(stream = $stdout)
      @stream = stream.tap do |str|
        # If the IO channel supports flushing the output immediately, then ensure it's enabled
        str.sync = str.respond_to?(:sync=)
      end
    end

    def print(*args)
      stream.print(*args)
    end

    def puts(*args)
      stream.puts(*args)
    end
    alias newline puts

    def clear
      system('clear')
    end

    def divider
      newline
      line(:default, :light) { DIVIDER * console_width }
    end

    # Prints plain text to the console
    # @param message [String] the text to write to the console
    #
    # @return [void]
    def help(message)
      line(:default) { message }
    end

    # Prints a summary of the total time and results for a batch run. If multiple tools, it will
    #  show the total tool count
    # @param tool_count [Integer] the number of commands run in the batch
    # @param seconds [Float] the total number of seconds the batch ran in realtime
    #
    # @return [void]
    def batch_summary(tool_count, seconds)
      newline
      text(:default, :bold) { "~#{seconds.round(1)} seconds" }
      if tool_count > 1
        line(:gray, :light) { " for #{tool_count} tools" }
      else
        newline
      end
    end

    # Print a tool summary using the name and description. Used before running a command to help
    #   identify which tool is running at any given moment.
    # @param tool [Tool] the tool to identify and describe
    #
    # @return [void]
    def tool_summary(tool)
      newline
      text(:default, :bold) { tool.name }
      line(:gray, :light) { " #{tool.description}" }
    end

    # Prints the text of a command to the console to help proactively expose potentials issues with
    #   syntax if Reviewer translated thte provided options in an unexpected way
    # @param command [String, Command] the command to identify on the console
    #
    # @return [void] [description]
    def current_command(command)
      newline
      line(:default, :bold) { 'Now Running:' }
      line(:gray) { String(command) }
    end

    def success(timer)
      text(:green, :bold) { 'Success' }
      text(:green) { " #{timer.total_seconds}s" }
      text(:yellow) { " (#{timer.prep_percent}% prep ~#{timer.prep_seconds}s)" } if timer.prepped?
      newline
    end

    def failure(details, command: nil)
      text(:red, :bold) { 'Failure' }
      text(:default, :light) { " #{details}" }
      newline

      return if command.nil?

      newline
      line(:default, :bold) { 'Failed Command:' }
      line(:gray) { String(command) }
    end

    def unrecoverable(details)
      line(:red, :bold) { 'Unrecoverable Error:' }
      line(:gray) { details }
    end

    def guidance(summary, details)
      return if details.nil?

      newline
      line(:default, :bold) { summary }
      line(:gray) { details }
    end

    def unfiltered(value)
      return if value.nil? || value.strip.empty?

      print value
    end

    protected

    def text(color = nil, weight = nil, &block)
      print "\e[#{style(color, weight)}m"
      print block.call
      print "\e[0m" # Reset
    end

    def line(color = nil, weight = nil, &block)
      text(color, weight) { block.call }
      newline
    end

    def style(color, weight)
      weight = WEIGHTS.fetch(weight) { WEIGHTS[:default] }
      color = COLORS.fetch(color) { COLORS[:default] }

      "#{weight};#{color}"
    end

    def console_width
      _height, width = IO.console.winsize

      width
    end
  end
end
