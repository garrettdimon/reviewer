# frozen_string_literal: true

module Reviewer
  # Provides a structure for running review commands and sharing results
  class Review
    attr_reader :tool, :batch, :runner, :output

    delegate :result,
             :seed,
             :timer,
             to: :runner

    delegate :exit_status,
             :rerunnable?,
             to: :result

    def self.perform_with(tools)
      results = {}
      tools.each do |tool|
        # More than one tool is a batch. Suppress successful output.
        # Just a single tool. Not a batch. Just show the output.
        runner = new(tool, batch: tools.size > 1)

        # Capture the exit status
        exit_status = runner.perform
        results[tool.key] = exit_status

        # If the tool fails, stop running other tools
        break unless runner.success?
      end
      results
    end

    def initialize(tool, batch: false)
      @tool = tool
      @batch = batch
      @runner = Runner.new
      @output = Output.new
    end

    def perform
      output.tool_summary(tool)

      if batch?
        run_quietly_and_benchmark
        show_results
      else
        run_verbosely
      end

      exit_status
    end

    def success?
      result.success?(max_exit_status: tool.max_exit_status)
    end

    private

    def needs_prep?
      tool.prepare_command? && tool.stale?
    end

    def batch?
      batch
    end

    def run_quietly_and_benchmark
      runner.tap do |runner|
        runner.preparation = preparation_command
        runner.command = review_command
      end.run_and_benchmark
    end

    def run_verbosely
      command = review_command(:no_silence)

      output.current_command(command)
      output.divider

      # Using the runner here would capture the output as plain text and strip it of any color or
      # or special characters. So it runs the full command with no quiet optiosn directly in its
      # full glory and leaves the tool's own output formatting in tact
      runner.direct(command)

      output.divider
      output.last_command(command)
    end

    def review_command(verbosity = nil)
      # 1. If an explicit verbosity is provided, use that.
      # 2. Otherwise, if it's in a batch of tools, suppress all the output
      # 3. Otherwise, when running a single tool, show all the output
      verbosity ||= batch? ? :total_silence : :no_silence

      tool.review_command(verbosity, seed: seed)
    end

    def preparation_command
      return nil unless needs_prep?

      tool.last_prepared_at = Time.current
      tool.preparation_command
    end

    def show_results
      if success?
        output.success(timer)
      else
        output.failure("Exit Status #{exit_status} · #{result}")
        show_guidance
      end
    end

    def show_guidance
      if result.executable_not_found?
        # The tool doesn't seem to be installed, so try to help them get back on track
        missing_executable_guidance
      elsif result.rerunnable?
        # There was a non-zero exit status, but since the output was suppressed, re-run  the command
        # without suppressing the output, and show suggestions to help fix the issue
        raw_output_with_guidance
      else
        # Something went really wrong, so showing `stderr` is really all there is left to do
        unrecoverable_guidance
      end
    end

    def missing_executable_guidance
      output.missing_executable_guidance(tool: tool, command: runner.command)
    end

    def raw_output_with_guidance
      run_verbosely
      output.syntax_guidance(
        ignore_link: tool.settings.links[:ignore_syntax],
        disable_link: tool.settings.links[:disable_syntax]
      )
    end

    def uncrecoverable_guidance
      output.unrecoverable(result.stderr)
    end
  end
end
