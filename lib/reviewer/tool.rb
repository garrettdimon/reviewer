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

    def install
      return unless settings.commands.key?(:install)

      ''
    end

    def prepare
      return unless settings.commands.key?(:prepare)

      ''
    end

    def review
      return unless settings.commands.key?(:review)

      ''
    end

    def format
      return unless settings.commands.key?(:format)

      ''
    end
  end
end
