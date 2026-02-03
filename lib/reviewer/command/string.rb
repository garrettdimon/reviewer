# frozen_string_literal: true

require_relative 'string/env'
require_relative 'string/flags'

module Reviewer
  class Command
    # Assembles tool tool_settings into a usable command string for the command type
    class String
      attr_reader :command_type, :tool_settings, :files

      # Creates a command string builder for a tool
      # @param command_type [Symbol] the command type (:install, :prepare, :review, :format)
      # @param tool_settings [Tool::Settings] the tool's configuration settings
      # @param files [Array<String>] files to include in the command
      #
      # @return [String] a command string builder instance
      def initialize(command_type, tool_settings:, files: [])
        @command_type = command_type
        @tool_settings = tool_settings
        @files = Array(files)
      end

      # Converts the command to a complete string ready for execution
      #
      # @return [String] the full command string
      def to_s
        to_a
          .map(&:strip) # Remove extra spaces on the components
          .join(' ')    # Merge the components
          .strip        # Strip extra spaces from the end result
      end

      # Converts the command to an array of its components
      #
      # @return [Array<String, nil>] env vars, body, flags, and files
      def to_a
        [
          env_variables,
          body,
          flags,
          files_string
        ].compact
      end

      # The string of environment variables built from a tool's configuration settings
      #
      # @return [String] the environment variable names and values concatened for the command
      def env_variables = Env.new(tool_settings.env).to_s

      # The base command string from the tool's configuration.
      # Uses the file-scoped command when files are present and one is configured.
      #
      # @return [String] the configured command for the command type
      def body
        file_scoped_command || tool_settings.commands.fetch(command_type)
      end

      # Gets the flags to be used in conjunction with the review command for a tool
      #   1. The `review` commands are the only commands that use flags
      #   2. If no flags are configured, this won't do anything
      #
      # @return [String] the concatenated list of flags to pass to the review command
      def flags
        return nil unless flags?

        Flags.new(tool_settings.flags).to_s
      end

      # Builds the files portion of the command string
      #
      # @return [String, nil] the formatted files string or nil if not applicable
      def files_string
        return nil unless files_applicable?

        file_list = files.join(tool_settings.files_separator)
        flag = tool_settings.files_flag

        flag.empty? ? file_list : "#{flag} #{file_list}"
      end

      private

      def file_scoped_command
        return nil unless files.any?

        tool_settings.files_command(command_type)
      end

      # Determines whether the string needs flags added
      #
      # @return [Boolean] true if it's a review command and it has flags configured
      def flags? = command_type == :review && tool_settings.flags.any?

      # Determines whether files should be appended to the command
      #
      # @return [Boolean] true if tool supports files and files were provided
      def files_applicable? = tool_settings.supports_files? && files.any?
    end
  end
end
