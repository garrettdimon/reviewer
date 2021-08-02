# frozen_string_literal: true

require_relative 'string/env'
require_relative 'string/flags'
require_relative 'string/verbosity'

module Reviewer
  class Command
    # Assembles tool tool_settings into a usable command string for the command type and verbosity
    class String
      include Conversions

      attr_reader :command_type, :tool_settings, :verbosity

      def initialize(command_type, tool_settings:, verbosity: nil)
        @command_type = command_type
        @tool_settings = tool_settings
        @verbosity = Verbosity(verbosity)
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
          verbosity_options
        ].compact
      end

      def env_variables
        Env.new(tool_settings.env).to_s
      end

      def body
        tool_settings.commands.fetch(command_type)
      end

      def flags
        # Flags to be used for `review` commands.
        # 1. The `review` commands are the only commands that use flags
        # 2. If no flags are configured, this won't do much
        #
        # Note: Since verbosity is handled separately, flags for 'quiet' are handled separately at a
        #   lower level by design and excluded from this check. They are not included with the other
        #   configured flags.
        return nil unless flags?

        Flags.new(tool_settings.flags).to_s
      end

      def verbosity_options
        Verbosity.new(tool_settings.quiet_option, level: verbosity.level).to_s
      end

      private

      # Determines whether the string needs flags added
      #
      # @return [Boolean] true if it's a review command and it has flags configured
      def flags?
        command_type == :review && tool_settings.flags.any?
      end
    end
  end
end
