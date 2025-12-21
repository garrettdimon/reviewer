# frozen_string_literal: true

require 'open3'

module Reviewer
  class Shell
    # Provides a structured interface for measuring realtime main while running comamnds
    class Timer
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
      def record_prep(&) = @prep = record(&)

      # Records the execution time for the block and assigns it to the `main` time
      # @param &block [Block] the commands to be timed
      #
      # @return [Float] the execution time for the main command
      def record_main(&) = @main = record(&)

      def prep_seconds = prep.round(2)
      def main_seconds = main.round(2)
      def total_seconds = total.round(2)
      def total = [prep, main].compact.sum
      def prepped? = !(prep.nil? || main.nil?)

      def prep_percent
        return nil unless prepped?

        (prep / total.to_f * 100).round
      end

      private

      def record(&) = Benchmark.realtime(&)
    end
  end
end
