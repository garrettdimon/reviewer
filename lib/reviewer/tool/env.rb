# frozen_string_literal: true

# Assembles tool environment variables into a single string or array
module Reviewer
  class Tool
    class Env
      attr_reader :env_pairs

      def initialize(env_pairs)
        @env_pairs = env_pairs
      end

      def to_s
        to_a.join(' ')
      end

      def to_a
        env = []
        env_pairs.each { |key, value| env << env(key, value) }
        env
      end


      private

      def env(key, value)
        "#{key.to_s.upcase}=#{value}".strip
      end
    end
  end
end
