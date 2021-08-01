# frozen_string_literal: true

module Reviewer
  module Commands
    # Provides a structure for running review commands and sharing results
    class Install
      include Conversions

      attr_accessor :verbosity

      attr_reader :tool

      def initialize(tool, verbosity = Verbosity::TOTAL_SILENCE)
        @tool = tool
        @verbosity = Verbosity(verbosity)
      end

      def command
        Command.new(tool, :install, verbosity)
      end

      def to_s
        command.string
      end
    end
  end
end
