# frozen_string_literal: true

module Reviewer
  # Wrapper for executng a command and printing the results
  class Runner
    attr_accessor :command

    attr_reader :shell,
                :output

    delegate :prepare?,       to: :tool
    delegate :tool,           to: :command
    delegate :result, :timer, to: :shell
    delegate :exit_status,    to: :result

    def initialize(tool, command_type, output: Reviewer.output)
      @command = Command.new(tool, command_type)
      @shell = Shell.new
      @output = output
    end

    def run_quietly
      run do
        # Fully capture all output so no extraneous noise is displayed
        run_with_capture

        # Display either the timer for success or the details for failure
        show_results
      end
    end

    def run_verbosely
      run do
        # Show the unfiltered output in its full fidelity
        run_without_capture

        # Help them get back on track if necessary
        show_guidance
      end
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

    def run
      # Show which tool is about to run
      output.tool_summary(tool)

      yield

      exit_status
    end

    def prepare_command
      # Touch the `last_prepared_at` timestamp for the tool so it waits before running again.
      tool.last_prepared_at = Time.current.utc

      @prepare_command ||= Command.new(tool, :prepare, command.verbosity)
    end




    def prepare_with_capture
      shell.capture_prep(prepare_command)
    end

    def run_with_capture
      @command.verbosity = Reviewer::Command::Verbosity::TOTAL_SILENCE
      prepare_with_capture if prepare?

      shell.capture_main(command)
    end

    def show_results
      # If it's a success, just show the timing, otherwise, show the output of the command
      success? ? show_timing_result : show_output
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






    def prepare_without_capture
      output.current_command(prepare_command)
      output.divider
      shell.direct(prepare_command)
    end

    def run_without_capture
      @command.verbosity = Reviewer::Command::Verbosity::NO_SILENCE
      prepare_without_capture if prepare?

      output.current_command(command)
      output.divider
      shell.direct(command)
      output.divider
    end

    def show_guidance
      # No need to show guidance if it went well
      return if success?

      Reviewer::Guidance.new(command: command, result: result, output: output).show
    end
  end
end
