# frozen_string_literal: true

require 'open3'

require_relative 'shell/result'
require_relative 'shell/timer'

module Reviewer
  # Handles running, timing, and capturing results for a command
  class Shell
    extend Forwardable

    # A lot of tools are run via rake which inclues some unhelpful drive when there's a non-zero
    #   exit status. This is what it starts with so Reviewer can recognize and remove it.
    RAKE_EXIT_DRIVEL = <<~DRIVEL
      rake aborted!
      Command failed with status (1)
    DRIVEL

    attr_reader :timer, :result, :captured_results

    def_delegators :@result, :exit_status

    # Initializes a Reviewer shell for running and benchmarking commands, and capturing output
    #
    # @return [Shell] a shell instance for running and benchmarking commands
    def initialize
      @timer = Timer.new
      @result = Result.new
    end

    # Run a command without capturing the output. This ensures the results are displayed realtime
    # if the command was run directly in the shell. So it keeps any color or other formatting that
    # would be stripped out by capturing $stdout as a basic string.
    # @param command [String] the command to run
    #
    # @return [Integer] exit status vaue of 0 when successful or 1 when unsuccessful
    def direct(command)
      result.exit_status = print_results(command) ? 0 : 1
    end

    def capture_prep(command, start_time = nil, average_time = 0)
      timer.record_prep { capture_results(command, start_time, average_time) }
    end

    def capture_main(command, start_time = nil, average_time = 0)
      timer.record_main { capture_results(command, start_time, average_time) }
    end

    private

    def capture_results(command, start_time, average_time)
      start_time ||= Time.now
      command = String(command)

      display_timer(start_time, average_time) do
        @captured_results = Open3.capture3(command)
      end

      @result = Result.new(*clean_captured_results)
    end

    def display_timer(start_time, average_time, &block)
      result = nil
      thread = Thread.new { block.call }

      while thread.alive?
        elapsed = (Time.now - start_time).to_f.round(1)
        progress = if average_time.zero?
                     "#{elapsed}s"
                   else
                     "#{((elapsed / average_time) * 100).round}%"
                   end

        $stdout.print "....#{progress}\r"
        $stdout.flush
      end

      result
    end

    def print_results(command)
      command = String(command)

      system(command)
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
    def clean_captured_results
      # Just so it's clear what captured_results[1] is referring to.
      stderr = captured_results[1]

      # We don't want to modify if it if there's no rake exit status noise in there.
      return captured_results unless stderr&.include?(RAKE_EXIT_DRIVEL)

      @captured_results[1] = stderr.split(RAKE_EXIT_DRIVEL).first

      captured_results
    end
  end
end
