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
        # @return [self]
        def initialize(env_pairs)
          @env_pairs = env_pairs
        end

        # Converts environment variables to a space-separated string
        #
        # @return [String] formatted environment variables (e.g., "KEY=value KEY2=value2")
        def to_s
          to_a.compact.join(' ')
        end

        # Converts environment variables to an array of KEY=value strings
        #
        # @return [Array<String, nil>] array of formatted env vars, nil for empty values
        def to_a
          env_pairs.map { |key, value| env(key, value) }
        end

        private

        def env(key, value)
          key_str = key.to_s.strip
          value_str = value.to_s.strip
          return nil if key_str.empty? || value_str.empty?

          value_str = "'#{value_str}'" if needs_quotes?(value)

          "#{key_str.upcase}=#{value_str}"
        end

        def needs_quotes?(value)
          value.is_a?(::String) && value.include?(' ')
        end
      end
    end
  end
end
