# frozen_string_literal: true

require_relative 'runner/strategies/quiet'
require_relative 'runner/strategies/verbose'

module Reviewer
  # Wrapper for executng a command and printing the results
  class Runner
    attr_accessor :strategy

    attr_reader :command, :shell, :output

    delegate :tool,           to: :command
    delegate :result, :timer, to: :shell
    delegate :exit_status,    to: :result

    def initialize(tool, command_type, strategy = Strategies::Quiet, output: Reviewer.output)
      @command = Command.new(tool, command_type)
      @strategy = strategy
      @shell = Shell.new
      @output = output
    end

    def run
      # Show which tool is about to run
      output.tool_summary(tool)

      # Run the provided strategy
      run_strategy

      # If it failed,
      guidance.show unless success?

      exit_status
    end

    def success?
      if review?
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

    def review?
      command.type == :review
    end

    def prepare_with_capture
      shell.capture_prep(prepare_command)
    end

    def prepare_without_capture
      output.current_command(prepare_command)
      output.divider
      shell.direct(prepare_command)
    end

    def run_with_capture
      shell.capture_main(command)
    end

    def run_without_capture
      output.current_command(command)
      output.divider
      shell.direct(command)
      output.divider
    end

    def show_results
      # If it's a success, just show the timing, otherwise, show the output of the command
      success? ? show_timing_result : show_command_output
    end

    private

    def run_prepare_step?
      command.type != :prepare && tool.prepare?
    end

    def run_strategy
      strategy.new(self).tap do |runner|
        runner.prepare if run_prepare_step?
        runner.run
      end
    end

    def prepare_command
      # Touch the `last_prepared_at` timestamp for the tool so it waits before running again.
      tool.last_prepared_at = Time.current.utc

      @prepare_command ||= Command.new(tool, :prepare, command.verbosity)
    end

    def show_timing_result
      output.success(timer)
    end

    def show_command_output
      output.failure("Exit Status #{exit_status}", command: command)

      # If it can't be rerun, then don't try
      return if result.total_failure?

      # In the future, this could conditionally print the results of stdout/stderr to save time.
      # The downside is that the content will display as a pure string stripped of all color.
      # So maybe if re-running will take longer than X seconds, we display the stripped output?
      run_without_capture
    end

    def guidance
      @guidance ||= Reviewer::Guidance.new(command: command, result: result, output: output)
    end
  end
end
