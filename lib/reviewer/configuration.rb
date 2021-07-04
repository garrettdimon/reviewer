# frozen_string_literal: true

module Reviewer
  # Configuration values container for Reviewer
  class Configuration
    DEFAULT_PATH = Dir.pwd.freeze
    DEFAULT_FILE_NAME = '.reviewer.yml'
    DEFAULT_FILE = "#{DEFAULT_PATH}/#{DEFAULT_FILE_NAME}"

    attr_accessor :file

    def initialize
      @file = DEFAULT_FILE
    end

    def tools
      @tools ||= Loader.new(file).configuration
    end

    # def self.tools
    #   new.tools
    # end
  end
end
