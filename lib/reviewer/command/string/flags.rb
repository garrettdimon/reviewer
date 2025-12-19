# frozen_string_literal: true

module Reviewer
  class Command
    class String
      # Translates tool flag settings from the tool's configuration values into a single string or
      #   array that can be used to generate the command string
      class Flags
        attr_reader :flag_pairs

        # Creates an instance of command-string friendly flags
        # @param flag_pairs [Hash] the flags (keys) and their values
        #
        # @return [self]
        def initialize(flag_pairs)
          @flag_pairs = flag_pairs
        end

        # Creates a string-friendly format to use in a command
        #
        # @return [String] a string of flags that can be safely passed to a command
        def to_s
          to_a.join(' ')
        end

        # Creates an array of all flag name/value pairs
        #
        # @return [Array<String>] array of all flag strings to use to when running the command
        def to_a
          flag_pairs.map { |key, value| flag(key, value) }
        end

        private

        def flag(key, value)
          dash = key.to_s.size == 1 ? '-' : '--'

          value = "'#{value}'" if needs_quotes?(value)

          "#{dash}#{key} #{value}".strip
        end

        def needs_quotes?(value)
          value.is_a?(::String) && value.include?(' ')
        end
      end
    end
  end
end
