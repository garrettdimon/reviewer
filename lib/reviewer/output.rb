# frozen_string_literal: true

require 'io/console/size' # For determining console width/height

require_relative 'output/formatting'
require_relative 'output/printer'

module Reviewer
  # Console display infrastructure — primitives for styled terminal output.
  # Domain-specific display logic lives in each concept's Formatter class.
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

    # Clears the terminal screen (no-op when output is not a TTY)
    # @return [void]
    def clear
      system('clear') if printer.tty?
    end

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

    private

    # Returns the current console width, falling back to a default
    # @return [Integer] the console width in columns
    def console_width
      return DEFAULT_CONSOLE_WIDTH if IO.console.nil?

      _height, width = IO.console.winsize

      width.positive? ? width : DEFAULT_CONSOLE_WIDTH
    end
  end
end
