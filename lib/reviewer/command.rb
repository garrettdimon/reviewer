# frozen_string_literal: true

require_relative 'command/string'
require_relative 'command/verbosity'

module Reviewer
  # The core funtionality to translate a tool, command type, and verbosity into a runnable command
  class Command
    include Conversions

    class InvalidTypeError < ArgumentError; end

    class NotConfiguredError < StandardError; end

    TYPES = %i[install prepare review format].freeze

    attr_reader :tool, :type

    attr_accessor :verbosity_level

    delegate :commands, to: :tool

    def initialize(tool, type, verbosity)
      @tool = Tool(tool)
      @type = type.to_sym
      @verbosity_level ||= :total_silence

      verify_type!
    end

    def string
      @string ||= Text.new(
        type,
        tool_settings: tool.settings,
        verbosity_level: verbosity_level
      ).to_s
    end

    def random_seed?
      string.include?(SEED_SUBSTITUTION_VALUE)
    end

    def valid_type?
      TYPES.include?(type)
    end

    def command_defined?
      commands.key?(type) && commands[type].present?
    end

    def verify_type!
      raise InvalidTypeError, "'#{type}' is not a supported command type. (Make sure it's not a typo.)" unless valid_type?
      raise NotConfiguredError, "The '#{type}' command is not configured for #{tool.name}.  (Make sure it's not a typo.)" unless command_defined?
    end
  end
end
