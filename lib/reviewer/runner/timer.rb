# frozen_string_literal: true

require 'open3'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    # Provides a structured interface for measuring realtime elapsed while running comamnds
    class Timer
      class NoRecordedPreparationError < StandardError; end

      attr_accessor :prep, :elapsed

      def initialize(elapsed: nil, prep: nil)
        @prep = prep
        @elapsed = elapsed
      end

      def record_prep(&block)
        @prep = record(&block)
      end

      def record_elapsed(&block)
        @elapsed = record(&block)
      end

      def prep?
        prep.present?
      end

      def prep_seconds
        prep.round(2)
      end

      def elapsed_seconds
        elapsed.round(2)
      end

      def prep_percent
        raise NoRecordedPreparationError unless prep.present?

        (prep / elapsed.to_f * 100).round
      end

      private

      def record(&block)
        Benchmark.realtime(&block)
      end
    end
  end
end
