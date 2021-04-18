# frozen_string_literal: true

require_relative "tool/command"
require_relative "tool/flags"
require_relative "tool/settings"

# Provides an instance of a specific tool
module Reviewer
  class Tool
    attr_reader :settings

    def initialize
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


    private

    def command
    end
  end
end
