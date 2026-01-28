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

      def hash = state.hash

      def eql?(other)
        self.class == other.class &&
          state == other.state
      end
      alias :== eql?

      def disabled? = config.fetch(:disabled) { false }
      def enabled? = !disabled?

      def name = config.fetch(:name) { tool_key.to_s.capitalize }
      def description = config.fetch(:description) { "(No description provided for '#{name}')" }
      def tags = config.fetch(:tags) { [] }
      def links = config.fetch(:links) { {} }
      def env = config.fetch(:env) { {} }
      def flags = config.fetch(:flags) { {} }

      def files_flag = config.dig(:files, :flag) || ''
      def files_separator = config.dig(:files, :separator) || ' '
      def files_pattern = config.dig(:files, :pattern)
      def supports_files? = config.key?(:files)

      # The collection of configured commands for the tool
      #
      # @return [Hash] all of the commands configured for the tool
      def commands = config.fetch(:commands) { {} }

      # The largest exit status that can still be considered a success for the command
      #
      # @return [Integer] the configured `max_exit_status` for the tool or 0 if one isn't configured
      def max_exit_status = commands.fetch(:max_exit_status) { 0 }

      protected

      def state = config.to_hash

      def load_config = Reviewer.tools.to_h.fetch(key) { {} }
    end
  end
end
