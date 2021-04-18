# frozen_string_literal: true

require "active_support/core_ext/string"
require_relative "tool/command"
require_relative "tool/env"
require_relative "tool/flags"
require_relative "tool/settings"
require_relative "tool/verbosity"

# Provides an instance of a specific tool
module Reviewer
  class Tool
    attr_reader :settings, :command

    def initialize(tool)
      @settings = Settings.new(tool)
      @command = Command.new(settings)
    end
  end
end
