# frozen_string_literal: true

require 'io/console' # For determining console width/height

module Reviewer
  class Output
    # Wrapper to encapsulate some lower-level details of printing to $stdout
    class Printer
      ESC = "\e["

      Token = Struct.new(:style, :content) do
        def to_s
          [
            style_string,
            content,
            reset_string
          ].join
        end

        private

        def style_string
          "#{ESC}#{weight};#{color}m"
        end

        def reset_string
          "#{ESC}0m"
        end

        def weight_key
          style_components[0]
        end

        def color_key
          style_components[1]
        end

        def weight
          {
            default: 0,
            bold: 1,
            light: 2,
            italic: 3
          }.fetch(weight_key)
        end

        def color
          {
            black: 30,
            red: 31,
            green: 32,
            yellow: 33,
            blue: 34,
            magenta: 35,
            cyan: 36,
            gray: 37,
            default: 39
          }.fetch(color_key)
        end

        def style_components
          {
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
          }.fetch(style)
        end
      end

      attr_reader :stream

      # Creates an instance of Output to print Reviewer activity and results to the console
      def initialize(stream = $stdout)
        @stream = stream.tap do |str|
          # If the IO channel supports flushing the output immediately, then ensure it's enabled
          str.sync = str.respond_to?(:sync=)
        end
      end

      def print(style, content)
        text(style, content)
      end

      def puts(style, content)
        text(style, content)
        stream.puts
      end

      def tty?
        stream.tty?
      end
      alias style_enabled? tty?

      private

      def text(style, content)
        if style_enabled?
          stream.print Token.new(style, content).to_s
        else
          stream.print content
        end
      end
    end
  end
end
