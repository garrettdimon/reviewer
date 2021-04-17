# frozen_string_literal: true

# Assembles tool settings into a usable command string
module Reviewer
  module Tool
    class Command
      attr_reader :settings, :silent

      def initialize(tool:, config:, silent: true)
        @settings = Settings.new(tool: tool, config: config)
        @silent = silent
      end

      def install
        ''
      end

      def prepare
        ''
      end

      def review
        ''
      end

      def format
        ''
      end
    end
  end
end
