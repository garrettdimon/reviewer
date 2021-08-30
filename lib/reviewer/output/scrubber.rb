# frozen_string_literal: true

module Reviewer
  class Output
    # Provides a structure interface for the results of running a command
    class Scrubber
      # A lot of tools are run via rake which inclues some unhelpful drive when there's a non-zero
      #   exit status. This is what it starts with so Reviewer can recognize and remove it.
      RAKE_ABORTED_TEXT = <<~DRIVEL
        rake aborted!
      DRIVEL

      attr_accessor :raw

      def initialize(raw)
        @raw = raw || ''
      end

      def clean
        rake_aborted_text? ? preceding_text : raw
      end

      private

      def rake_aborted_text?
        raw.include?(RAKE_ABORTED_TEXT)
      end

      # Removes any unhelpful rake exit status details from $stderr. Reviewew uses `exit` when a
      #   command fails so that the resulting command-line exit status can be interpreted correctly
      #   in CI and similar environments. Without that exit status, those environments wouldn't
      #   recognize the failure. As a result, Rake almost always adds noise that begins with the value
      #   in RAKE_EXIT_DRIVEL when `exit` is called. Frequently, that RAKE_EXIT_DRIVEL is the only
      #   information in $stderr, and it's not helpful in the human-readable output, but other times
      #   when a valid exception occurs, there's useful error information preceding RAKE_EXIT_DRIVEL.
      #   So this ensures that the unhelpful part is always removed so the output is cluttered with
      #   red herrings since the command is designed to fail with an exit status of 1 under normal
      #   operation with tool failures.
      def preceding_text
        raw.split(RAKE_ABORTED_TEXT).first
      end
    end
  end
end
