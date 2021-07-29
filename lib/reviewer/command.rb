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

    attr_accessor :verbosity

    def initialize(tool, type, verbosity = Verbosity::TOTAL_SILENCE)
      @tool = Tool(tool)
      @type = type.to_sym
      @verbosity = Verbosity(verbosity)

      verify_type!
    end

    def string
      @string ||= String.new(
        type,
        tool_settings: tool.settings,
        verbosity: verbosity
      ).to_s
    end
    alias to_s string

    private

    def valid_type?
      TYPES.include?(type)
    end

    def configured?
      tool.has_command?(type)
    end

    def verify_type!
      raise InvalidTypeError, "'#{type}' is not a supported command type." unless valid_type?
      raise NotConfiguredError, "The '#{type}' command is not configured for #{tool.name}." unless configured?
    end
  end
end
