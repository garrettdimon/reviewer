# frozen_string_literal: true

require 'yaml/store'

module Reviewer
  # Provides an instance of a storage resource for persisting data across runs
  class History
    attr_reader :file, :store

    def initialize(file = Reviewer.configuration.history_file)
      @file = file
      @store = YAML::Store.new(file)
    end

    def set(group, attribute, value)
      store.transaction do |s|
        s[group] = {} if s[group].nil?
        s[group][attribute] = value
      end
    end

    def get(group, attribute)
      store.transaction do |s|
        s[group].nil? ? nil : s[group][attribute]
      end
    end

    def reset!
      return unless File.exist?(file)

      FileUtils.rm(file)
    end

    def self.reset!
      new.reset!
    end
  end
end
