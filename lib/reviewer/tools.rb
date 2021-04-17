# frozen_string_literal: true

require_relative "tools/loader"
require_relative "tools/settings"

# Provides a collection of the configured tools
module Reviewer
  module Tools
    def self.all
      []
    end

    def self.enabled
      []
    end

    def self.disabled
      []
    end
  end
end
