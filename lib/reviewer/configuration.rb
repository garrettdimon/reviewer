# frozen_string_literal: true

module Reviewer
  class Configuration
    DEFAULT_CONFIGURATION_PATH = Dir.pwd.freeze
    DEFAULT_CONFIGURATION_FILE = '.reviewer.yml'.freeze

    attr_accessor :file

    def initialize
      @file = "#{DEFAULT_CONFIGURATION_PATH}/#{DEFAULT_CONFIGURATION_FILE}"
    end
  end
end
