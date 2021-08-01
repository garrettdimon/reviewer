# frozen_string_literal: true

require 'open3'

module Reviewer
  class Shell
    # Provides a structured interface for measuring realtime main while running comamnds
    class Timer
      attr_accessor :prep, :main

      def initialize(prep: nil, main: nil)
        @prep = prep
        @main = main
      end

      def record_prep(&block)
        @prep = record(&block)
      end

      def record_main(&block)
        @main = record(&block)
      end

      def prep_seconds
        prep.round(2)
      end

      def main_seconds
        main.round(2)
      end

      def total_seconds
        total.round(2)
      end

      def prep_percent
        return nil unless prep.present? && main.present?

        (prep / total.to_f * 100).round
      end

      def total
        [prep, main].compact.sum
      end

      private

      def record(&block)
        Benchmark.realtime(&block)
      end
    end
  end
end
