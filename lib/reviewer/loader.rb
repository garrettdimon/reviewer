# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/hash/indifferent_access"

# Provides a collection of the configured tools
module Reviewer
  class Loader
    class MissingConfigurationError < StandardError; end
    class InvalidConfigurationError < StandardError; end

    attr_reader :configuration

    def initialize
      @configuration = HashWithIndifferentAccess.new(configuration_hash)
    end

    def to_h
      configuration
    end

    private

    def configuration_hash
      @configuration_hash ||= YAML.load_file(Reviewer.configuration.file)
    rescue Errno::ENOENT
      raise MissingConfigurationError, "Tools configuration file couldn't be found - #{Reviewer.configuration.file}"
    rescue Psych::SyntaxError => e
      raise InvalidConfigurationError, "Tools configuration file has a syntax error - #{e.message}"
    end
  end
end
