# frozen_string_literal: true

module Reviewer
  class Configuration
    attr_accessor :file

    def initialize
      @file = 'commands.yml'
    end
  end
end
