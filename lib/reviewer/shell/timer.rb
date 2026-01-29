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
      attr_accessor :prep, :main

      # A 'Smart' timer that understands preparation time and main time and can easily do the math
      #   to help determine what percentage of time was prep. The times can be passed in directly or
      #   recorded using the `record_prep` and `record_main` methods
      # @param prep: nil [Float] the amount of time in seconds the preparation command ran
      # @param main: nil [Float] the amount of time in seconds the primary command ran
      #
      # @return [self]
      def initialize(prep: nil, main: nil)
        @prep = prep
        @main = main
      end

      # Records the execution time for the block and assigns it to the `prep` time
      # @param &block [Block] the commands to be timed
      #
      # @return [Float] the execution time for the preparation
      def record_prep(&block) = @prep = record(&block)

      # Records the execution time for the block and assigns it to the `main` time
      # @param &block [Block] the commands to be timed
      #
      # @return [Float] the execution time for the main command
      def record_main(&block) = @main = record(&block)

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

      def prepped? = !(prep.nil? || main.nil?)

      # The percentage of total time spent on preparation
      #
      # @return [Integer, nil] percentage (0-100) or nil if not prepped
      def prep_percent
        return nil unless prepped?

        (prep / total.to_f * 100).round
      end

      private

      def record(&block) = Benchmark.realtime(&block)
    end
  end
end
