# frozen_string_literal: true

require 'open3'

require_relative 'shell/result'
require_relative 'shell/timer'

module Reviewer
  # Handles running, timing, and capturing results for a command
  class Shell
    attr_reader :timer, :result

    delegate :exit_status, to: :result

    # Initializes a Reviewer shell for running and benchmarking commands, and capturing output
    #
    # @return [Shell] a shell instance for running and benchmarking commands
    def initialize
      @timer = Timer.new
      @result = Result.new
    end

    # Run a command without capturing the output. This ensures the results are displayed the same as
    # if the command was run directly in the shell. So it keeps any color or other formatting that
    # would be stripped out by capturing $stdout as a basic string.
    # @param command [String] the command to run
    #
    # @return [Integer] exit status vaue of 0 when successful or 1 when unsuccessful
    def direct(command)
      result.exit_status = print_results(command) ? 0 : 1
    end

    def capture_prep(command)
      timer.record_prep { capture_results(command) }
    end

    def capture_main(command)
      timer.record_main { capture_results(command) }
    end

    private

    def capture_results(command)
      command = String(command)

      captured_results = Open3.capture3(command)
      @result = Result.new(*captured_results)
    end

    def print_results(command)
      command = String(command)

      system(command)
    end
  end
end
