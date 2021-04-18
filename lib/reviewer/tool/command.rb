# frozen_string_literal: true

# Assembles tool tool_settings into a usable command string
module Reviewer
  class Tool
    class Command
      class InvalidTypeError < StandardError; end
      class NotConfiguredError < StandardError; end

      TYPES = %i[install prepare review format].freeze

      attr_reader :command_type, :tool_settings, :verbosity_level

      def initialize(command_type, tool_settings:, verbosity_level: nil)
        @command_type = command_type
        @tool_settings = tool_settings
        @verbosity_level = verbosity_level

        verify_command_type!
      end

      def to_s
        to_a
          .map(&:strip)
          .join(' ')
          .strip
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
        # :review commands are the only commands that use flags (except the :quiet_flag)
        return nil unless review?

        Flags.new(tool_settings.flags).to_s
      end

      def verbosity
        Verbosity.new(tool_settings.quiet_flag, level: verbosity_level).to_s
      end


      private

      def review?
        command_type == :review
      end

      def valid_command?
        TYPES.include?(command_type)
      end

      def command_defined?
        tool_settings.commands.key?(command_type)
      end

      def verify_command_type!
        raise InvalidTypeError, "'#{body}' is not a supported command type. (Make sure it's not a typo.)" unless valid_command?
        raise NotConfiguredError, "The '#{body}' command is not configured for #{tool_settings.name}.  (Make sure it's not a typo.)" unless command_defined?
      end
    end
  end
end
