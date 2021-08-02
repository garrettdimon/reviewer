# frozen_string_literal: true

module Reviewer
  # Wrapper for executng a command and printing the results
  class Runner
    attr_accessor :command

    attr_reader :shell,
                :output

    delegate :tool, :type,               to: :command
    delegate :result, :timer,            to: :shell
    delegate :exit_status, :rerunnable?, to: :result

    def initialize(tool, command_type, verbosity, output: Reviewer.output)
      @command = Command.new(tool, command_type, verbosity)
      @shell = Shell.new
      @output = output
    end

    def run_quietly
      identify_and_prepare_tool

      run
      success? ? show_timing_result : rerun_verbosely

      exit_status
    end

    def run_verbosely
      identify_and_prepare_tool

      show_raw_output_block
      show_guidance

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

    def run
      shell.capture_main(command)
    end

    def show_raw_output_block
      verbose_command = Command.new(tool, command.type, Reviewer::Command::Verbosity::NO_SILENCE)

      output.current_command(verbose_command)

      unless verbose_command.string.include?('quiet')
        output.divider
        shell.direct(verbose_command.string)
        output.divider
      end

      show_guidance
    end

    def show_current_tool
      output.tool_summary(tool)
    end

    def show_timing_result
      output.success(timer)
    end

    def rerun_verbosely
      output.failure("Exit Status #{exit_status} · #{result}")
      show_raw_output_block unless result.total_failure?
    end

    def show_guidance
      if result.executable_not_found?
        show_missing_executable_guidance
      elsif result.cannot_execute?
        show_unrecoverable_guidance
      else
        show_syntax_guidance
      end
    end

    def show_missing_executable_guidance
      return unless result.executable_not_found?

      output.missing_executable_guidance(tool: tool, command: shell.command)
    end

    def show_unrecoverable_guidance
      output.unrecoverable(result.stderr)
    end

    def show_syntax_guidance
      output.syntax_guidance(
        ignore_link: tool.settings.links[:ignore_syntax],
        disable_link: tool.settings.links[:disable_syntax]
      )
    end
  end
end
