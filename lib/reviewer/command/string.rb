# frozen_string_literal: true

require_relative 'string/env'
require_relative 'string/flags'

module Reviewer
  class Command
    # Assembles tool tool_settings into a usable command string for the command type
    class String
      include Conversions

      attr_reader :command_type, :tool_settings, :files

      def initialize(command_type, tool_settings:, files: [])
        @command_type = command_type
        @tool_settings = tool_settings
        @files = Array(files)
      end

      def to_s
        to_a
          .map(&:strip) # Remove extra spaces on the components
          .join(' ')    # Merge the components
          .strip        # Strip extra spaces from the end result
      end

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

      def body = tool_settings.commands.fetch(command_type)

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
