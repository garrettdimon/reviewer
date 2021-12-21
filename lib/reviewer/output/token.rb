# frozen_string_literal: true

module Reviewer
  class Output
    # Simple class for streamlining the output of 'tokens' representing a style and content
    #
    # @author [garrettdimon]
    #
    class Token
      ESC = "\e["

      attr_accessor :style, :content

      def initialize(style, content)
        @style = style
        @content = content
      end

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
  end
end
