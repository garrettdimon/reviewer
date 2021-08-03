# frozen_string_literal: true

module Reviewer
  # Wrapper for executng a command and printing the results
  class Runner
    attr_accessor :command

    attr_reader :shell,
                :output

    delegate :tool,           to: :command
    delegate :result, :timer, to: :shell
    delegate :exit_status,    to: :result

    def initialize(tool, command_type, output: Reviewer.output)
      @command = Command.new(tool, command_type)
      @shell = Shell.new
      @output = output
    end

    def run_quietly
      identify_and_prepare_tool

      # Fully capture all output so no extraneous noise is displayed
      run_with_capture

      # If it's a success, just show the timing, otherwise, show the output of the command
      success? ? show_timing_result : show_output

      exit_status
    end

    def run_verbosely
      identify_and_prepare_tool

      # Show the unfiltered output in its full fidelity
      run_without_capture

      # Help them get back on track
      show_guidance unless success?

      exit_status
    end

    def success?
      if command.type == :review
        # Some tools (ex. yarn audit) return a range of non-zero exit statuses and almost never
        # return 0. Those tools can be configured to accept a non-zero exit status so they aren't
        # constantly considered to be failing over minor issues.
        exit_status <= tool.max_exit_status
      else
        # When command types other than reviews are run, they either do the thing or they don't. In
        # those cases, anything other than a 0 isn't acceptable.
        exit_status.zero?
      end
    end

    private

    def identify_and_prepare_tool
      output.tool_summary(tool)
      prepare if tool.prepare?
    end

    def prepare
      # Set up the prepare command using the same verbosity level that it's being run with.
      prepare_command = Command.new(tool, :prepare, command.verbosity)

      # Run and benchmark the prepare command
      shell.capture_prep(prepare_command)

      # Touch the `last_prepared_at` timestamp for the tool so it waits before running again.
      tool.last_prepared_at = Time.current.utc
    end

    def run_with_capture
      command.verbosity = Reviewer::Command::Verbosity::TOTAL_SILENCE
      shell.capture_main(command)
    end

    def run_without_capture
      command.verbosity = Reviewer::Command::Verbosity::NO_SILENCE
      output.current_command(command)

      output.divider
      shell.direct(command)
      output.divider
    end

    def show_output
      output.failure("Exit Status #{exit_status}", command: command)

      # If it can't be rerun, then don't try
      return if result.total_failure?

      run_without_capture
      show_guidance
    end

    def show_timing_result
      output.success(timer)
    end

    def show_guidance
      Reviewer::Guidance.new(command: command, result: result, output: output).show
    end
  end
end
