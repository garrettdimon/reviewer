# frozen_string_literal: true

# Assembles tool flag settings into a single string or array
module Reviewer
  class Tool
    class Flags
      attr_reader :flag_pairs

      def initialize(flag_pairs)
        @flag_pairs = flag_pairs
      end

      def to_s
        to_a.join(' ')
      end

      def to_a
        flags = []
        flag_pairs.each { |key, value| flags << flag(key, value) }
        flags
      end


      private

      def flag(key, value)
        dash = key.to_s.size == 1 ? '-' : '--'

        value = needs_quotes?(value) ? "'#{value}'" : value

        "#{dash}#{key} #{value}".strip
      end

      def needs_quotes?(value)
        value.is_a?(String) && value.include?(' ')
      end
    end
  end
end
