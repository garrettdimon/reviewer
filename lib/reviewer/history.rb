# frozen_string_literal: true

require 'yaml/store'

module Reviewer
  # Provides an interface to a local storage resource for persisting data across runs. For example,
  # it enables remembering when `prepare` commands were run for reviews so they can be run less
  # frequently and thus improve performance.
  #
  # It also enables remembering seeds across runs. Eventually `rvw rerun` could reuse the seeds from
  # the immediately preceding run to more easily facilitate fixing tests that are accidentally
  # order-dependent. Or it could automatically record a list of seeds that led to failures.
  #
  # Long term, it could serve to record timing details across runs to provide insight to min, max,
  # and means. Those times could then be used for reviewer to make more informed decisions about
  # default behavior to ensure each run remains fast.
  class History
    attr_reader :file, :store

    # Creates an instance of a YAML::Store-backed history file.
    # @param file = Reviewer.configuration.history_file [Pathname] the history file to store data
    #
    # @return [History] an instance of history
    def initialize(file = Reviewer.configuration.history_file)
      @file = file
      @store = YAML::Store.new(file)
    end

    # Saves a value to a given location in the history
    # @param group [Symbol] the first-level key to use for saving the value--frequently a tool name
    # @param attribute [Symbol] the second-level key to use for retrieving the value
    # @param value [Primitive] any value that can be cleanly stored in YAML
    #
    # @return [Primitive] the value being stored
    def set(group, attribute, value)
      store.transaction do |s|
        s[group] = {} if s[group].nil?
        s[group][attribute] = value
      end
    end

    # Retrieves a stored value from the history file
    # @param group [Symbol] the first-level key to use for retrieving the value
    # @param attribute [Symbol] the second-level key to use for retrieving the value
    #
    # @return [Primitive] the value being stored
    def get(group, attribute)
      store.transaction do |s|
        s[group].nil? ? nil : s[group][attribute]
      end
    end

    # Removes the existing history file.
    #
    # @return [void]
    def reset!
      return unless File.exist?(file)

      FileUtils.rm(file)
    end

    # Convenience class method for removing the history file.
    #
    # @return [void]
    def self.reset!
      new.reset!
    end
  end
end
