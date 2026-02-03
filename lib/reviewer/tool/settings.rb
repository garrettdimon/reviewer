# frozen_string_literal: true

module Reviewer
  class Tool
    # Converts/casts tool configuration values and provides appropriate default values if not set.
    class Settings
      attr_reader :tool_key, :config

      alias key tool_key

      # Creates an instance of settings for retrieving values from the configuration file
      # @param tool_key [Symbol] the unique identifier for the tool in the config file
      # @param config [Hash] the configuration values to examine for the settings
      #
      # @return [Settings]
      def initialize(tool_key, config:)
        @tool_key = tool_key.to_sym
        @config = config
      end

      # Returns a hash code for comparing settings instances
      #
      # @return [Integer] hash code based on configuration state
      def hash = state.hash

      # Compares two settings instances for equality based on their configuration
      # @param other [Settings] the settings to compare against
      # @return [Boolean] true if both have the same configuration
      def eql?(other)
        self.class == other.class &&
          state == other.state
      end
      alias :== eql?

      def skip_in_batch?
        if config.key?(:skip_in_batch)
          config.fetch(:skip_in_batch) { false }
        else
          config.fetch(:disabled) { false }
        end
      end

      def disabled? = skip_in_batch?
      def enabled? = !skip_in_batch?

      # The human-readable name of the tool
      #
      # @return [String] the configured name or capitalized tool key
      def name = config.fetch(:name) { tool_key.to_s.capitalize }

      # The human-readable description of what the tool does
      #
      # @return [String] the configured description or a default placeholder
      def description = config.fetch(:description) { "(No description provided for '#{name}')" }

      # The tags used to categorize and filter the tool
      #
      # @return [Array<String>] configured tags or empty array
      def tags = config.fetch(:tags) { [] }

      # The collection of reference links for the tool (home, install, usage, etc.)
      #
      # @return [Hash] configured links or empty hash if none
      def links = config.fetch(:links) { {} }

      # The environment variables to set when running the tool
      #
      # @return [Hash] configured env vars or empty hash
      def env = config.fetch(:env) { {} }

      # The CLI flags to pass to the tool's review command
      #
      # @return [Hash] configured flags or empty hash
      def flags = config.fetch(:flags) { {} }

      # The CLI flag used to pass files to the tool (e.g., '--files')
      #
      # @return [String] the configured flag or empty string if files are passed directly
      def files_flag = config.dig(:files, :flag) || ''

      # The separator used to join multiple file paths in the command
      #
      # @return [String] the configured separator or a space by default
      def files_separator = config.dig(:files, :separator) || ' '

      # The glob pattern used to filter which files this tool should process
      #
      # @return [String, nil] the pattern (e.g., '*.rb') or nil if not configured
      def files_pattern = config.dig(:files, :pattern)

      # The test framework to use for mapping source files to test files
      #
      # @return [String, nil] the framework name ('minitest' or 'rspec') or nil if not configured
      def map_to_tests = config.dig(:files, :map_to_tests)

      def supports_files? = config.key?(:files)

      # The regex pattern for extracting a summary detail from tool output
      #
      # @return [String, nil] the configured pattern or nil
      def summary_pattern = config.dig(:summary, :pattern)

      # The label template for displaying the extracted summary detail
      #
      # @return [String, nil] the configured label or nil
      def summary_label = config.dig(:summary, :label)

      # Returns the file-scoped command override for a given command type.
      # When configured, this command replaces the standard command when files are passed.
      #
      # @param command_type [Symbol] the command type (:review, :format)
      # @return [String, nil] the file-scoped command or nil if not configured
      def files_command(command_type) = config.dig(:files, command_type)

      # The collection of configured commands for the tool
      #
      # @return [Hash] all of the commands configured for the tool
      def commands = config.fetch(:commands) { {} }

      # The largest exit status that can still be considered a success for the command
      #
      # @return [Integer] the configured `max_exit_status` for the tool or 0 if one isn't configured
      def max_exit_status = commands.fetch(:max_exit_status) { 0 }

      protected

      # Returns the configuration as a plain hash for comparison
      # @return [Hash] the configuration state
      def state = config.to_hash
    end
  end
end
