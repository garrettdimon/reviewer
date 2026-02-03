# frozen_string_literal: true

require 'pathname'

module Reviewer
  # Configuration values container for Reviewer
  #
  # @!attribute file
  #   @return [Pathname] the pathname for the primary configuraton file
  # @!attribute history_file
  #   @return [Pathname] the pathname for the history file to store data across runs
  # @!attribute printer
  #   @return [Output::Printer] the printer instance for console output
  #
  # @author [garrettdimon]
  #
  class Configuration
    DEFAULT_PATH = Dir.pwd.freeze

    DEFAULT_CONFIG_FILE_NAME = '.reviewer.yml'
    DEFAULT_HISTORY_FILE_NAME = '.reviewer_history.yml'

    DEFAULT_CONFIG_LOCATION = "#{DEFAULT_PATH}/#{DEFAULT_CONFIG_FILE_NAME}".freeze
    DEFAULT_HISTORY_LOCATION = "#{DEFAULT_PATH}/#{DEFAULT_HISTORY_FILE_NAME}".freeze

    attr_accessor :file, :history_file
    attr_reader :printer

    def initialize
      @file = Pathname(DEFAULT_CONFIG_LOCATION)
      @history_file = Pathname(DEFAULT_HISTORY_LOCATION)

      # Future Configuration Options:
      # - seed_substitution_value(string): Currently a constant of `$SEED` in Reviewer::Command, but
      #   may need to be configurable in case any command-line strings have other legitimate uses
      #   for the value such that it may need to be override. Ideally, it woudl be changed to3
      #   something obscure enough that conflicts wouldn't happen, but you never know
      # - benchmark_everything(:dev, :optimize): Use the `time_up` gem to measure and show all the results
      #   for each tool and step to help identify and reduce bottlenecks. It would mainly be a flag
      #   for use in development, but it could also help folks troubleshoot their speed in finer
      #   detail than the standard Reviewer output
      # - default_preparation_refresh(integer time): Right now, it's hard-coded at 6 hours, but that may require
      #   tuning for individual tools
    end
  end
end
