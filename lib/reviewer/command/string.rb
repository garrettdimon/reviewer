# frozen_string_literal: true

require_relative 'string/env'
require_relative 'string/flags'
require_relative 'string/verbosity'

module Reviewer
  class Command
    # Assembles tool tool_settings into a usable command string for the command type and verbosity
    class String
      attr_reader :command_type, :tool_settings, :verbosity_level

      def initialize(command_type, tool_settings:, verbosity_level: nil)
        @command_type = command_type
        @tool_settings = tool_settings
        @verbosity_level = verbosity_level
      end

      def to_s
        to_a
          .map(&:strip) # Remove extra spaces on the components
          .join(' ')    # Merge the components
          .strip        # Strip extra spaces from the end result
      end

      def to_a
        [
          env,
          body,
          flags,
          verbosity
        ].compact
      end

      def env
        Env.new(tool_settings.env).to_s
      end

      def body
        tool_settings.commands.fetch(command_type)
      end

      def flags
        # :review commands are the only commands that use flags
        # And if no flags are configured, this won't do much
        # Flags for 'quiet' are handled separately by design and excluded from this check.
        return nil unless review? && tool_settings.flags.any?

        Flags.new(tool_settings.flags).to_s
      end

      def verbosity
        Verbosity.new(tool_settings.quiet_option, level: verbosity_level).to_s
      end

      private

      def review?
        command_type == :review
      end
    end
  end
end
