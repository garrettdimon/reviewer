# frozen_string_literal: true

require_relative 'command/string'

module Reviewer
  # The core funtionality to translate a tool, command type, and verbosity into a runnable command
  class Command
    include Conversions

    SEED_SUBSTITUTION_VALUE = '$SEED'

    attr_reader :tool

    attr_accessor :type

    # Creates an instance of the Command class to synthesize a command string using the tool,
    # command type, and verbosity.
    # @param tool [Tool, Symbol] a tool or tool key to use to look up the command and options
    # @param type [Symbol] the desired command type (:install, :prepare, :review, :format)
    #
    # @return [Command] the intersection of a tool, command type, and verbosity
    def initialize(tool, type)
      @tool = Tool(tool)
      @type = type.to_sym
    end

    # The final command string with all of the conditions appled
    #
    # @return [String] the final, valid command string to run
    def string
      @string ||= seed_substitution? ? seeded_string : raw_string
    end
    alias to_s string

    # Generates a seed that can be re-used across runs so that the results are consistent across
    # related runs for tools that would otherwise change the seed automatically every run.
    # Since not all tools will use the seed, there's no need to generate it in the initializer.
    # Instead, it's memoized if it's used.
    #
    # @return [Integer] a random integer to pass to tools that use seeds
    def seed
      @seed ||= Random.rand(100_000)

      # Store the seed for reference
      Reviewer.history.set(tool.key, :last_seed, @seed)

      @seed
    end

    # The raw command string before any substitutions. For example, since seeds need to remain
    # consistent from one run to the next, they're
    #
    # @return [type] [description]
    def raw_string
      @raw_string ||= String.new(type, tool_settings: tool.settings).to_s
    end

    private

    # The version of the command with the SEED_SUBSTITUTION_VALUE replaced
    #
    # @return [String] the command string with the SEED_SUBSTITUTION_VALUE replaced
    def seeded_string
      # Update the string with the memoized seed value
      raw_string.gsub(SEED_SUBSTITUTION_VALUE, seed.to_s)
    end

    # Determines if the raw command string has a SEED_SUBSTITUTION_VALUE that needs replacing
    #
    # @return [Boolean] true if the raw command string contains the SEED_SUBSTITUTION_VALUE
    def seed_substitution?
      raw_string.include?(SEED_SUBSTITUTION_VALUE)
    end
  end
end
