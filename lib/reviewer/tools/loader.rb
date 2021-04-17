# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/hash/indifferent_access"

module Reviewer
  module Tools
    class Loader
      class MissingConfigurationError < StandardError; end
      class InvalidConfigurationError < StandardError; end

      attr_reader :configuration

      def initialize
        @configuration = HashWithIndifferentAccess.new(configuration_hash)
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
end
