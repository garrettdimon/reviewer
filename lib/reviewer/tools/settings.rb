# frozen_string_literal: true

module Reviewer
  module Tools
    class Settings
      class MissingReviewCommandError < StandardError; end

      attr_accessor :tool, :config

      def initialize(tool:, config:)
        @tool = tool
        @config = config

        # Ideally, folks would fill out everything, but realistically, the 'review' command is the only required value.
        # If the key is missing, or maybe there was a typo, fail right away.
        raise MissingReviewCommandError, "'#{name}' does not have a 'review' key under 'commands' in your tools configuration" unless commands.key?(:review)
      end

      def disabled?
        config.fetch(:disabled) { false }
      end

      def enabled?
        !disabled?
      end

      def key
        tool.to_sym
      end

      def name
        tool.to_s
      end

      def description
        config.fetch(:description) { '' }
      end

      def tags
        config.fetch(:tags) { [] }
      end

      def links
        config.fetch(:links) { {} }
      end

      def env
        config.fetch(:env) { {} }
      end

      def flags
        config.fetch(:flags) { {} }
      end

      def commands
        config.fetch(:commands) { {} }
      end
    end
  end
end
