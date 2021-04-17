# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/hash/indifferent_access"

module Reviewer
  module Tools
    class Loader
      attr_reader :configuration

      def initialize
        raw_hash = YAML.load_file(Reviewer.configuration.file)
        @configuration = HashWithIndifferentAccess.new(raw_hash)
      end
    end
  end
end
