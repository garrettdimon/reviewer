# frozen_string_literal: true

require 'pathname'

module Reviewer
  # Configuration values container for Reviewer
  class Configuration
    DEFAULT_PATH = Dir.pwd.freeze

    DEFAULT_CONFIG_FILE_NAME = '.reviewer.yml'
    DEFAULT_HISTORY_FILE_NAME = '.reviewer_history.yml'

    DEFAULT_CONFIG_LOCATION = "#{DEFAULT_PATH}/#{DEFAULT_CONFIG_FILE_NAME}"
    DEFAULT_HISTORY_LOCATION = "#{DEFAULT_PATH}/#{DEFAULT_HISTORY_FILE_NAME}"

    attr_accessor :file, :history_file, :logger

    def initialize
      @file = Pathname(DEFAULT_CONFIG_LOCATION)
      @history_file = Pathname(DEFAULT_HISTORY_LOCATION)
      @logger = Logger.new
    end
  end
end
