# frozen_string_literal: true

module Reviewer
  class Output
    # Shared display vocabulary included by all domain formatters.
    # Provides common constants and helper methods for formatting output.
    module Formatting
      CHECKMARK = "\u2713"
      XMARK = "\u2717"

      private

      # Formats a duration in seconds for display
      # @param seconds [Float, nil] the duration to format
      # @return [String] formatted duration (e.g., "1.23s")
      def format_duration(seconds)
        "#{seconds.to_f.round(2)}s"
      end

      # Returns the appropriate status mark
      # @param success [Boolean] whether the operation succeeded
      # @return [String] checkmark or x mark
      def status_mark(success) = success ? CHECKMARK : XMARK

      # Returns the appropriate style key for a status
      # @param success [Boolean] whether the operation succeeded
      # @return [Symbol] :success or :failure
      def status_style(success) = success ? :success : :failure

      # Pluralizes a word based on count
      # @param count [Integer] the count
      # @param singular [String] the singular form
      # @param plural [String] the plural form (defaults to singular + "s")
      # @return [String] formatted count with word (e.g., "1 issue" or "3 issues")
      def pluralize(count, singular, plural = "#{singular}s")
        count == 1 ? "1 #{singular}" : "#{count} #{plural}"
      end
    end
  end
end
