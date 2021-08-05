# frozen_string_literal: true

module Reviewer
  class Command
    class String
      # Assembles tool environment variables into a single string or array
      class Env
        attr_reader :env_pairs

        # Creates an instance of env variables for a tool to help generate the command string
        # @param env_pairs [Hash] [description]
        #
        # @return [self] an instance of
        def initialize(env_pairs)
          @env_pairs = env_pairs
        end

        def to_s
          to_a.compact.join(' ')
        end

        def to_a
          env = []
          env_pairs.each { |key, value| env << env(key, value) }
          env
        end

        private

        def env(key, value)
          return nil if key.to_s.strip.empty? || value.to_s.strip.empty?

          value = needs_quotes?(value) ? "'#{value}'" : value

          "#{key.to_s.strip.upcase}=#{value.to_s.strip}"
        end

        def needs_quotes?(value)
          value.is_a?(::String) && value.include?(' ')
        end
      end
    end
  end
end
