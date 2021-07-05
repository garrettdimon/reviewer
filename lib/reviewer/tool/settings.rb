# frozen_string_literal: true

module Reviewer
  class Tool
    # Converts/casts tool configuration values and provides default values if not set
    class Settings
      attr_reader :tool

      def initialize(tool, config: nil)
        @tool = tool
        @config = config
      end

      def ==(other)
        self.class == other.class &&
          state == other.state
      end
      alias eql? ==

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

      protected

      def config
        @config || Reviewer.tools.to_h.fetch(tool.to_sym) { {} }
      end

      def state
        config.to_hash
      end
    end
  end
end
