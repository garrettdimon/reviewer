# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'

module Reviewer
  # Provides a collection of the configured tools
  class Loader
    class MissingConfigurationError < StandardError; end

    class InvalidConfigurationError < StandardError; end

    class MissingReviewCommandError < StandardError; end

    attr_reader :configuration, :file

    def initialize(file = Reviewer.configuration.file)
      @file = file
      @configuration = HashWithIndifferentAccess.new(configuration_hash)

      validate_configuration!
    end

    def to_h
      configuration
    end

    def self.configuration
      self.new.configuration
    end

    private

    def validate_configuration!
      # Any additional guidance for configuration issues will live here
      require_review_commands!
    end

    def require_review_commands!
      configuration.each do |key, value|
        commands = value[:commands]

        next if commands.key?(:review)

        # Ideally, folks would want to fill out everything to receive the most benefit,
        # but realistically, the 'review' command is the only required value. If the key
        # is missing, or maybe there was a typo, fail right away.
        raise MissingReviewCommandError, "'#{key}' does not have a 'review' key under 'commands' in `#{file}`"
      end
    end

    def configuration_hash
      @configuration_hash ||= YAML.load_file(@file)
    rescue Errno::ENOENT
      raise MissingConfigurationError, "Tools configuration file couldn't be found at `#{file}`"
    rescue Psych::SyntaxError => e
      raise InvalidConfigurationError, "Tools configuration file (#{file}) has a syntax error: #{e.message}"
    end
  end
end
