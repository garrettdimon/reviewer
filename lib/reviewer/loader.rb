# frozen_string_literal: true

require 'yaml'

module Reviewer
  # Provides a collection of the configured tools
  class Loader
    # Raised when the .reviewer.yml configuration file cannot be found
    class MissingConfigurationError < StandardError; end

    # Raised when the .reviewer.yml file contains invalid YAML syntax
    class InvalidConfigurationError < StandardError; end

    # Raised when a configured tool is missing a required review command
    class MissingReviewCommandError < StandardError; end

    attr_reader :configuration, :file

    # Creates a loader instance for the configuration file
    # @param file [Pathname] the path to the configuration YAML file
    #
    # @return [Loader] a loader with parsed configuration
    # @raise [MissingConfigurationError] if the file doesn't exist
    # @raise [InvalidConfigurationError] if the YAML is malformed
    # @raise [MissingReviewCommandError] if a tool lacks a review command
    def initialize(file = Reviewer.configuration.file)
      @file = file
      @configuration = configuration_hash

      validate_configuration!
    end

    # Converts the loader to its configuration hash
    #
    # @return [Hash] the parsed configuration
    def to_h = configuration

    # Loads and returns the tools configuration hash
    #
    # @return [Hash] the parsed configuration from the YAML file
    def self.configuration = new.configuration

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
      @configuration_hash ||= Psych.safe_load_file(@file, symbolize_names: true)
    rescue Errno::ENOENT
      raise MissingConfigurationError, "Tools configuration file couldn't be found at `#{file}`"
    rescue Psych::SyntaxError => e
      raise InvalidConfigurationError, "Tools configuration file (#{file}) has a syntax error: #{e.message}"
    end
  end
end
