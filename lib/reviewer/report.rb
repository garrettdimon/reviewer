# frozen_string_literal: true

require 'json'

module Reviewer
  # Collects results from multiple tool runs and provides serialization
  class Report
    attr_reader :results, :duration

    def initialize
      @results = []
      @duration = nil
    end

    # Adds a Runner::Result to the collection
    #
    # @param result [Runner::Result] the result to add
    # @return [Array<Runner::Result>] the updated results array
    def add(result)
      @results << result
    end

    # Records the total duration for all tool runs
    #
    # @param seconds [Float] the total elapsed time in seconds
    # @return [Float] the recorded duration
    def record_duration(seconds)
      @duration = seconds
    end

    # Whether all tools in the report succeeded
    #
    # @return [Boolean] true if all results are successful
    def success?
      results.all?(&:success)
    end

    # Returns the highest exit status from all results
    #
    # @return [Integer] the maximum exit status, or 0 if empty
    def max_exit_status
      results.map(&:exit_status).max || 0
    end

    # Converts the report to a hash suitable for serialization
    #
    # @return [Hash] structured hash with summary and tool results
    def to_h
      {
        success: success?,
        summary: {
          total: results.size,
          passed: results.count(&:success),
          failed: results.count { |r| !r.success },
          duration: duration
        },
        tools: results.map(&:to_h)
      }
    end

    # Converts the report to formatted JSON
    #
    # @return [String] JSON representation of the report
    def to_json(*_args)
      JSON.pretty_generate(to_h)
    end
  end
end
