# frozen_string_literal: true

module Reviewer
  class Command
    # Defines the possible verbosity options for running commands
    class Verbosity
      include Comparable

      class InvalidLevelError < ArgumentError; end

      # Use the quiet flag and send everything to dev/null.
      # For some tools "quiet" means "less noisy" rather than truly silent.
      # So in those cases, dev/null handles lingering noise.
      TOTAL_SILENCE = :total_silence

      # Just the quiet flag for the tool. Basically, let the tool determine the useful output.
      TOOL_SILENCE = :tool_silence

      # Let the output scroll for eternity
      NO_SILENCE = :no_silence

      # For validation and casting purposes
      LEVELS = [
        TOTAL_SILENCE,
        TOOL_SILENCE,
        NO_SILENCE
      ].freeze

      attr_accessor :level

      # Create an instance of verbosity
      # @param level [Symbol] one of the values of verbosity defined by LEVELS
      #
      # @return [Command::Verbosity] an instance of verbosity
      def initialize(level)
        @level = level.to_sym

        verify_level!
      end

      def <=>(other)
        level <=> other.level
      end

      def to_s
        level.to_s
      end

      def to_i
        LEVELS.index(level)
      end

      def to_sym
        level
      end
      alias key to_sym

      private

      def verify_level!
        raise InvalidLevelError, "Invalid Verbosity Level: '#{level}'" unless LEVELS.include?(level)
      end
    end
  end
end
