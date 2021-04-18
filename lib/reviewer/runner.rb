# frozen_string_literal: true

require_relative "tool/command"
require_relative "tool/env"
require_relative "tool/flags"
require_relative "tool/settings"
require_relative "tool/verbosity"

# Provides an instance of a specific tool
module Reviewer
  class Runner
    def initialize
    end

    def self.run(tool, command)
      cmd = tool.review_command

      pp cmd
    end
  end
end
