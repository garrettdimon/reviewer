# frozen_string_literal: true

# Converts/casts tool configuration values and provides default values if not set
module Reviewer
  class Tool
    class Settings
      class MissingReviewCommandError < StandardError; end

      attr_reader :tool, :config

      def initialize(tool, config: nil)
        @tool = tool
        @config = config || Reviewer.configuration.tools.fetch(tool.to_sym) { {} }

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

      def has_prepare_command?
        commands.key?(:prepare) && commands[:prepare].present?
      end

      def has_install_command?
        commands.key?(:install) && commands[:install].present?
      end

      def has_install_link?
        links.key?(:install) && links[:install].present?
      end

      def key
        tool.to_sym
      end

      def name
        config.fetch(:name) { tool.to_s.titleize }
      end

      def description
        config.fetch(:description) { "(No description provided for '#{name}')" }
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

      def max_exit_status
        commands.fetch(:max_exit_status) { 0 }
      end

      def quiet_flag
        commands.fetch(:quiet_flag) { '' }
      end
    end
  end
end
