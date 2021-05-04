# frozen_string_literal: true

module Reviewer
  class Tool
    # Assembles tool settings and provided context for silencing output
    class Verbosity
      class InvalidLevelError < StandardError; end
      # :total_silence = Use the quiet flag and send everything to dev/null.
      #                  For some tools "quiet" means "less noisy" rather than truly silent.
      #                  So in those cases, dev/null handles lingering noise.
      # :tool_silence  = Just the quiet flag
      # :no_silence    = Let the output scroll for eternity
      LEVELS = %i[total_silence tool_silence no_silence].freeze
      SEND_TO_DEV_NULL = '> /dev/null'

      attr_reader :flag, :level

      def initialize(flag, level: :tool_silence)
        @flag = flag

        raise InvalidLevelError, "Invalid Verbosity Level: '#{level}'" unless LEVELS.include?(level)

        @level = level
      end

      def to_s
        to_a.map(&:strip).join(' ').strip
      end

      def to_a
        case level
        when :total_silence then [flag, SEND_TO_DEV_NULL].compact
        when :tool_silence  then [flag].compact
        when :no_silence    then []
        end
      end
    end
  end
end
