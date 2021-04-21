# frozen_string_literal: true

module Reviewer
  # Provides a collection of the configured tools
  module Tools
    def self.all
      tools = []
      Reviewer.configuration.tools.each_key do |key|
        tools << Tool.new(key)
      end
      tools
    end
  end
end
