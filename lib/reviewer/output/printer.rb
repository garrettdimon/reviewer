# frozen_string_literal: true

require 'io/console' # For determining console width/height

module Reviewer
  class Output
    # Wrapper to encapsulate some lower-level details of printing to $stdout.
    # Handles ANSI styling directly via a pre-computed STYLES constant.
    class Printer
      ESC = "\e["
      RESET = "#{ESC}0m"

      # Weight codes
      WEIGHTS = { default: 0, bold: 1, light: 2, italic: 3 }.freeze

      # Color codes
      COLORS = {
        black: 30, red: 31, green: 32, yellow: 33,
        blue: 34, magenta: 35, cyan: 36, gray: 37, default: 39
      }.freeze

      # Style definitions: [weight, color]
      STYLE_DEFS = {
        success_bold: %i[bold green],
        success: %i[default green],
        success_light: %i[light green],
        error: %i[bold red],
        failure: %i[default red],
        warning: %i[bold yellow],
        warning_light: %i[light yellow],
        source: %i[italic default],
        bold: %i[default default],
        default: %i[default default],
        muted: %i[light gray]
      }.freeze

      # Pre-computed ANSI escape strings for each style
      STYLES = STYLE_DEFS.transform_values do |weight_key, color_key|
        "#{ESC}#{WEIGHTS.fetch(weight_key)};#{COLORS.fetch(color_key)}m"
      end.freeze

      attr_reader :stream

      # Creates an instance of Output to print Reviewer activity and results to the console
      def initialize(stream = $stdout)
        @stream = stream.tap do |str|
          # If the IO channel supports flushing the output immediately, then ensure it's enabled
          str.sync = str.respond_to?(:sync=)
        end
      end

      # Prints styled content without a newline
      # @param style [Symbol] the style key for color and weight
      # @param content [String] the text to print
      #
      # @return [void]
      def print(style, content)
        text(style, content)
      end

      # Prints styled content followed by a newline
      # @param style [Symbol] the style key for color and weight
      # @param content [String] the text to print
      #
      # @return [void]
      def puts(style, content)
        text(style, content)
        stream.puts
      end

      def tty? = stream.tty?
      alias style_enabled? tty?

      private

      def text(style, content)
        if style_enabled?
          stream.print "#{STYLES.fetch(style)}#{content}#{RESET}"
        else
          stream.print content
        end
      end
    end
  end
end
