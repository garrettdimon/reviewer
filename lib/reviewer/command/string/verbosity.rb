# frozen_string_literal: true

module Reviewer
  class Command
    class String
      # Assembles tool settings and provided context for silencing output
      class Verbosity
        include ::Reviewer::Conversions

        # Even when tools provide a quiet flag, not all treat it as complete silence. In order to
        # ensure no extraneous noise is written to the console in some contexts, command output
        # occasionally needs to be sent to dev null to ensure there's no clutter.
        SEND_TO_DEV_NULL = '> /dev/null'

        attr_reader :flag, :level

        # A wrapper for translating a desired verbosity into the correct strings to append to the
        # command so that any output is appropriately silenced for the context under which it's
        # currently being executed.
        # @param flag [String] the tool-level flag to be used for silencing output
        # @param level: Reviewer::Command::Verbosity::TOOL_SILENCE [Symbol] the target level for
        #   silence for the the command
        #
        # @return [type] [description]
        def initialize(flag, level: Reviewer::Command::Verbosity::TOOL_SILENCE)
          @flag = String(flag)
          @level = Verbosity(level)
        end

        # Converts the verbosity to a string that can be appended to a command string
        #
        # @return [String] the string to be appended to commands to ensure the correct verbosity
        def to_s
          to_a.map(&:strip).join(' ').strip
        end

        # Collection of values to be joined to ensure the correct verbosity
        #
        # @return [Array<String>] the values that need to be joined to ensure the correct verbosity
        #   for the context
        def to_a
          case level.key
          when Reviewer::Command::Verbosity::TOTAL_SILENCE then [flag, SEND_TO_DEV_NULL].compact
          when Reviewer::Command::Verbosity::TOOL_SILENCE  then [flag].compact
          else []
          end
        end
      end
    end
  end
end
