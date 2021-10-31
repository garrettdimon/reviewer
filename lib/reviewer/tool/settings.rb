# frozen_string_literal: true

module Reviewer
  class Tool
    # Converts/casts tool configuration values and provides appropriate default values if not set.
    class Settings
      attr_reader :tool_key, :config

      alias key tool_key

      # Creates an instance of settings for retrieving values from the configuration file.
      # @param tool_key [Symbol] the unique identifier for the tool in the config file
      # @param config: nil [Hash] the configuration values to examine for the settings
      #
      # @return [self]
      def initialize(tool_key, config: nil)
        @tool_key = tool_key.to_sym
        @config = config || load_config
      end

      def hash
        state.hash
      end

      def eql?(other)
        self.class == other.class &&
          state == other.state
      end
      alias :== eql?

      def disabled?
        config.fetch(:disabled, false)
      end

      def enabled?
        !disabled?
      end

      def name
        config.fetch(:name) { tool_key.to_s.capitalize }
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

      protected

      def state
        config.to_hash
      end

      def load_config
        Reviewer.tools.to_h.fetch(key) { {} }
      end
    end
  end
end
