# frozen_string_literal: true

module Reviewer
  # Configuration for Reviewer
  class Configuration
    DEFAULT_CONFIGURATION_PATH = Dir.pwd.freeze
    DEFAULT_CONFIGURATION_FILE = '.reviewer.yml'

    attr_accessor :file

    def initialize
      @file = "#{DEFAULT_CONFIGURATION_PATH}/#{DEFAULT_CONFIGURATION_FILE}"
    end

    def tools
      @tools ||= Loader.new.to_h
    end
  end
end
