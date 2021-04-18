# frozen_string_literal: true

# Assembles tool settings into a usable command string
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

        "#{dash}#{key} #{value}".strip
      end
    end
  end
end
