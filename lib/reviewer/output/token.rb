# frozen_string_literal: true

module Reviewer
  class Output
    # Simple class for streamlining the output of 'tokens' representing a style and content
    #
    # @author [garrettdimon]
    #
    class Token
      ESC = "\e["

      # @!attribute style
      #   @return [Symbol] the style key (e.g., :success, :failure, :muted)
      # @!attribute content
      #   @return [String] the text content to display
      attr_accessor :style, :content

      # Creates a styled output token
      # @param style [Symbol] the style key for color and weight
      # @param content [String] the text content to display
      #
      # @return [Token] a styled token instance
      def initialize(style, content)
        @style = style
        @content = content
      end

      # Converts the token to an ANSI-styled string
      #
      # @return [String] the content wrapped in ANSI escape codes
      def to_s
        [
          style_string,
          content,
          reset_string
        ].join
      end

      private

      def style_string = "#{ESC}#{weight};#{color}m"
      def reset_string = "#{ESC}0m"
      def weight_key = style_components[0]
      def color_key = style_components[1]

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
