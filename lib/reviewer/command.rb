# frozen_string_literal: true

require_relative 'command/string'
require_relative 'command/verbosity'

module Reviewer
  # The core funtionality to translate a tool, command type, and verbosity into a runnable command
  class Command
    include Conversions

    class InvalidTypeError < StandardError
      attr_reader :provided_type

      def initialize(provided_type)
        @provided_type = provided_type
        super(message)
      end

      private

      def valid_command_types
        Command::TYPES.map { |type| "'#{type}'" }.join(', ')
      end

      def message
        "'#{provided_type}' is not a supported command type. Must be one of: #{valid_command_types}"
      end
    end

    class NotConfiguredError < StandardError
      attr_reader :provided_type, :tool

      def initialize(provided_type, tool)
        @provided_type = provided_type
        @tool = tool
        super(message)
      end

      private

      def available_command_types_for(tool)
        valid_command_types = Command::TYPES
        configured_command_types = tool.commands.keys

        configured_command_types
          .intersection(valid_command_types)
          .join(', ')
      end

      def message
        "'#{provided_type}' is not defined for #{tool.name}. Must be one of: #{available_command_types_for(@tool)}"
      end
    end

    SEED_SUBSTITUTION_VALUE = '$SEED'

    TYPES = %i[install prepare review format].freeze

    # TYPES = {
    #   install: ::Reviewer::Commands::Install,
    #   prepare: ::Reviewer::Commands::Prepare,
    #   review:  ::Reviewer::Commands::Review,
    #   format:  ::Reviewer::Commands::Format,
    # }.freeze

    attr_reader :tool, :type

    def initialize(tool, type, verbosity = Verbosity::TOTAL_SILENCE)
      @tool = Tool(tool)
      @type = type.to_sym
      @verbosity = Verbosity(verbosity)

      raise InvalidTypeError.new(type) unless valid_type?
      raise NotConfiguredError.new(type, @tool) unless configured_for_tool?
    end

    def string
      @string ||= seed_substitution? ? seeded_string : raw_string
    end
    alias to_s string

    def verbosity
      @verbosity
    end

    def verbosity=(verbosity)
      @verbosity = Verbosity(verbosity)

      # Unmemoize string since the verbosity has been changed
      @string = nil
    end

    private

    def raw_string
      @raw_string ||= String.new(
        type,
        tool_settings: tool.settings,
        verbosity: verbosity
      ).to_s
    end

    def seeded_string
      # Store the seed for reference
      Reviewer.history.set(tool.key, :last_seed, seed)

      # Update the string with the memoized seed value
      raw_string.gsub(SEED_SUBSTITUTION_VALUE, seed.to_s)
    end

    def seed_substitution?
      raw_string.include?(SEED_SUBSTITUTION_VALUE)
    end

    # Generates a seed that can be re-used across runs so that the results are consistent across
    # related runs for tools that would otherwise change the seed automatically every run.
    # Since not all tools will use the seed, there's no need to generate it in the initializer.
    # Instead, it's memoized if it's used.
    #
    # @return [Integer] a random integer to pass to tools that use seeds
    def seed
      @seed ||= Random.rand(100_000)
    end

    # def methodology
    #   command_class.new(tool, verbosity)
    # end

    # def command_class
    #   TYPES.fetch(type)
    # end

    def valid_type?
      TYPES.include?(type)
    end

    def configured_for_tool?
      tool.has_command?(type)
    end
  end
end
