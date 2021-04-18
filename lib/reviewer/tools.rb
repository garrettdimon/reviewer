# frozen_string_literal: true

# Provides a collection of the configured tools
module Reviewer
  module Tools
    def self.all
      tools = []
      Reviewer.configuration.tools.keys.each do |key|
        tools << Tool.new(key)
      end
      tools
    end
  end
end
