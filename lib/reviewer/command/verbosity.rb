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
      SILENT = :silent

      # Just the quiet flag for the tool. Basically, let the tool determine the useful output.
      QUIET = :quiet

      # Let the output scroll for eternity
      VERBOSE = :verbose

      # For validation and casting purposes
      LEVELS = [SILENT, QUIET, VERBOSE].freeze

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

      # Converts to the verbosity level as a string
      #
      # @return [String] the verbosity level as a string
      def to_s
        level.to_s
      end

      # Converts to the verbosity level index
      #
      # @return [Integer] the verbosity level as an integer from Command::Verbosity::LEVELS
      def to_i
        LEVELS.index(level)
      end

      # Converts to the verbosity level as a symbol
      #
      # @return [Symbol] the verbosity level's underlying symbol
      def to_sym
        level
      end
      alias key to_sym

      private

      # Ensures the level is valid by verifying it exists in Command::Verbosity::LEVELS
      #
      # @raise [InvalidLevelError] if the level does not exist in Command::Verbosity::LEVELS
      # @return [void]
      def verify_level!
        raise InvalidLevelError, "Invalid Verbosity Level: '#{level}'" unless LEVELS.include?(level)
      end
    end
  end
end
