# frozen_string_literal: true

require 'open3'
require 'pty'

require_relative 'shell/result'
require_relative 'shell/timer'

module Reviewer
  # Handles running, timing, and capturing results for a command
  class Shell
    extend Forwardable

    attr_reader :timer, :result, :captured_results

    def_delegators :@result, :exit_status

    # Initializes a Reviewer shell for running and benchmarking commands, and capturing output
    #
    # @return [Shell] a shell instance for running and benchmarking commands
    def initialize
      @timer = Timer.new
      @result = Result.new
      @captured_results = nil
    end

    # Run a command via PTY, streaming output in real-time while capturing it for later use
    # (e.g. failed file extraction). PTY allocates a pseudo-terminal so the child process
    # preserves ANSI colors and interactive behavior.
    # @param command [String] the command to run
    #
    # @return [Result] the captured result including stdout and exit status
    def direct(command)
      command = String(command)
      buffer = +''

      reader, _writer, pid = PTY.spawn(command)
      begin
        reader.each_line do |line|
          $stdout.print line
          buffer << line
        end
      rescue Errno::EIO
        # Expected when child process exits before all output is read
      end

      _, status = Process.waitpid2(pid)
      @result = Result.new(buffer, nil, status)
    rescue Errno::ENOENT
      @result = Result.new(buffer, nil, nil)
      @result.exit_status = Result::EXIT_STATUS_CODES[:executable_not_found]
    end

    # Captures and times the preparation command execution
    # @param command [String, Command] the command to run
    #
    # @return [Result] the captured result including stdout, stderr, and exit status
    def capture_prep(command) = timer.record_prep { capture_results(command) }

    # Captures and times the main command execution
    # @param command [String, Command] the command to run
    #
    # @return [Result] the captured result including stdout, stderr, and exit status
    def capture_main(command) = timer.record_main { capture_results(command) }

    private

    # Open3.capture3 returns stdout, stderr, and status separately. Keeping them
    # separate matters for FailedFiles, which merges the streams intentionally
    # when scanning for file paths after a failure.
    def capture_results(command)
      command = String(command)

      @captured_results = Open3.capture3(command)
      @result = Result.new(*@captured_results)
    rescue Errno::ENOENT
      @result = Result.new(nil, nil, nil)
      @result.exit_status = Result::EXIT_STATUS_CODES[:executable_not_found]
    end
  end
end
