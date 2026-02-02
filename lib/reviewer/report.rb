# frozen_string_literal: true

require 'json'
require_relative 'report/formatter'

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

    # Whether all executed tools in the report succeeded (excludes missing and skipped)
    #
    # @return [Boolean] true if all executed results are successful
    def success?
      executed_results.all?(&:success?)
    end

    # Returns the highest exit status from executed results (excludes missing and skipped)
    #
    # @return [Integer] the maximum exit status, or 0 if empty
    def max_exit_status
      executed_results.map(&:exit_status).max || 0
    end

    # Returns results for tools whose executables were not found
    #
    # @return [Array<Runner::Result>] missing tool results
    def missing_results
      results.select(&:missing?)
    end

    # Whether any tools were missing
    #
    # @return [Boolean] true if any results are missing
    def missing?
      missing_results.any?
    end

    # Returns data for missing tools (name and key)
    #
    # @return [Array<Runner::Result>] the missing results with tool info
    def missing_tools
      missing_results
    end

    # Converts the report to a hash suitable for serialization
    #
    # @return [Hash] structured hash with summary and tool results
    def to_h
      {
        success: success?,
        summary: {
          total: results.size,
          passed: results.count(&:success?),
          failed: results.count { |result| !result.success? && !result.missing? },
          missing: missing_results.size,
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

    private

    # Results for tools that actually executed (excludes skipped and missing)
    #
    # @return [Array<Runner::Result>] executed results only
    def executed_results
      results.select(&:executed?)
    end
  end
end
