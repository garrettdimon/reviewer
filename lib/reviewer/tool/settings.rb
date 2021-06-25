# frozen_string_literal: true

module Reviewer
  class Tool
    # Converts/casts tool configuration values and provides default values if not set
    class Settings
      class MissingReviewCommandError < StandardError; end

      attr_reader :tool, :config

      def initialize(tool, config: nil)
        @tool = tool
        @config = config || Tools.configured.fetch(tool.to_sym) { {} }

        # Ideally, folks would want to fill out everything to receive the most benefit,
        # but realistically, the 'review' command is the only required value. If the key
        # is missing, or maybe there was a typo, fail right away.
        raise MissingReviewCommandError, "'#{key}' does not have a 'review' key under 'commands' in `#{Reviewer.configuration.file}`" unless commands.key?(:review)
      end

      def disabled?
        config.fetch(:disabled, false)
      end

      def enabled?
        !disabled?
      end

      def prepare_command?
        commands.key?(:prepare) && commands[:prepare].present?
      end

      def install_command?
        commands.key?(:install) && commands[:install].present?
      end

      def format_command?
        commands.key?(:format) && commands[:format].present?
      end

      def install_link?
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
        commands.fetch(:max_exit_status, 0)
      end

      def quiet_option
        commands.fetch(:quiet_option, '')
      end
    end
  end
end
