# frozen_string_literal: true

module Reviewer
  # Provides a structure for running format commands and sharing results
  class Format
    attr_reader :tool, :runner, :output

    delegate :result,
             :seed,
             :timer,
             to: :runner

    delegate :exit_status,
             to: :result

    def self.perform_with(tools)
      results = tools.map do |tool|
        # More than one tool is a batch. Suppress successful output.
        # Just a single tool. Not a batch. Just show the output.
        runner = new(tool)

        # Capture the exit status
        exit_status = runner.perform

        [tool.key, exit_status]
      end
      results.to_h { |result| result }.compact
    end

    def initialize(tool)
      @tool = tool
      @runner = Runner.new
      @output = Output.new
    end

    def perform
      return unless tool.format_command?

      output.tool_summary(tool)

      run_verbosely
      show_guidance

      exit_status
    end

    def needs_prep?
      tool.prepare_command? && tool.stale?
    end

    def success?
      result.success?(max_exit_status: tool.max_exit_status)
    end

    private

    def run_verbosely
      command = tool.format_command

      output.current_command(command)
      output.divider

      # Using the runner here would capture the output as plain text and strip it of any color or
      # or special characters. So it runs the full command with no quiet optiosn directly in its
      # full glory and leaves the tool's own output formatting in tact
      runner.direct(command)

      output.divider
      output.last_command(command)
    end

    def show_results
      if success?
        output.success(timer)
      else
        output.failure("Exit Status #{exit_status} · #{result}")
      end
    end

    def show_guidance
      return unless result.executable_not_found?

      missing_executable_guidance
    end

    def missing_executable_guidance
      output.missing_executable_guidance(tool: tool, command: runner.command)
    end
  end
end
