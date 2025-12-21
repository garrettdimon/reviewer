# frozen_string_literal: true

require 'io/console' # For determining console width/height

module Reviewer
  class Output
    # Wrapper to encapsulate some lower-level details of printing to $stdout
    class Printer
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

      def tty? = stream.tty?
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
