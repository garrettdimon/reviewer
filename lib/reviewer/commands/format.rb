# frozen_string_literal: true

module Reviewer
  module Commands
    # Provides a structure for running format commands and sharing results
    class Format
      attr_accessor :verbosity

      attr_reader :tool

      def initalize(tool, verbosity = :tool_silence)
        @tool = tool
        @verbosity = Verbosity(verbosity)
      end

      def command
        Command.new(tool, :format, verbosity)
      end

      def to_s
        command.string
      end
    end
  end
end
