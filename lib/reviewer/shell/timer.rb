# frozen_string_literal: true

require 'open3'

module Reviewer
  class Shell
    # Provides a structured interface for measuring realtime main while running comamnds
    class Timer
      # @!attribute prep
      #   @return [Float, nil] the preparation time in seconds
      # @!attribute main
      #   @return [Float, nil] the main execution time in seconds
      attr_reader :prep, :main

      # A timer that tracks preparation and main execution times separately.
      # Times can be passed directly or recorded using `record_prep` and `record_main`.
      # @param prep [Float, nil] the preparation time in seconds
      # @param main [Float, nil] the main execution time in seconds
      #
      # @return [Timer]
      def initialize(prep: nil, main: nil)
        @prep = prep
        @main = main
      end

      # Records the execution time for the block and assigns it to the `prep` time
      # @param block [Block] the commands to be timed
      #
      # @return [Float] the execution time for the preparation
      def record_prep(&) = @prep = record(&)

      # Records the execution time for the block and assigns it to the `main` time
      # @param block [Block] the commands to be timed
      #
      # @return [Float] the execution time for the main command
      def record_main(&) = @main = record(&)

      # The preparation time rounded to two decimal places
      #
      # @return [Float] prep time in seconds
      def prep_seconds = prep.round(2)

      # The main execution time rounded to two decimal places
      #
      # @return [Float] main time in seconds
      def main_seconds = main.round(2)

      # The total execution time (prep + main) rounded to two decimal places
      #
      # @return [Float] total time in seconds
      def total_seconds = total.round(2)

      # The total time (prep + main) without rounding
      #
      # @return [Float] total time in seconds
      def total = [prep, main].compact.sum

      # Whether both prep and main times have been recorded
      #
      # @return [Boolean] true if both phases were timed
      def prepped? = [prep, main].all?

      # The percentage of total time spent on preparation
      #
      # @return [Integer, nil] percentage (0-100) or nil if not prepped
      def prep_percent
        return nil unless prepped?

        (prep / total.to_f * 100).round
      end

      private

      def record(&) = Benchmark.realtime(&)
    end
  end
end
