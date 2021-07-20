# frozen_string_literal: true

require 'open3'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    class Timer
      attr_accessor :prep, :elapsed

      def initialize(elapsed: nil, prep: nil)
        @prep = prep
        @elapsed = elapsed
      end

      def record_prep
        @prep = record { yield }
      end

      def record_elapsed
        @elapsed = record { yield }
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
        (prep.to_f / elapsed.to_f * 100).round
      end

      private

      def record
        Benchmark.realtime { yield }
      end
    end
  end
end
