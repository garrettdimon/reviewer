# frozen_string_literal: true

require 'io/console' # For determining console width/height

module Reviewer
  class Output
    # ANSI terminal escape sequences for styled console output.
    # Extracted from Printer so style definitions are separated from printing mechanics.
    module AnsiStyles
      ESC = "\e["
      RESET = "#{ESC}0m".freeze

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
    end

    # Wrapper to encapsulate some lower-level details of printing to $stdout.
    # Handles ANSI styling via the pre-computed AnsiStyles::STYLES constant.
    class Printer
      include AnsiStyles

      attr_reader :stream

      # Creates a printer for styled console output
      # @param stream [IO] the output stream to write to
      #
      # @return [Printer]
      def initialize(stream = $stdout)
        @stream = stream
        @stream.sync = true
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

      # Writes content directly to the stream without styling.
      # Skips if content is nil or blank.
      #
      # @param content [String, nil] the raw text to write
      # @return [void]
      def write_raw(content)
        return if content.to_s.strip.empty?

        stream << content
      end

      # Whether the output stream is a TTY (interactive terminal)
      # @return [Boolean] true if the stream supports ANSI styling
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
