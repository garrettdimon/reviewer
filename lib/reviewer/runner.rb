# frozen_string_literal: true

require 'open3'

require_relative 'runner/output'
require_relative 'runner/result'
require_relative 'runner/timer'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    attr_accessor :tool, :command_type

    attr_reader :last_command_run,
                :timer,
                :result

    def initialize(tool, command_type)
      @tool = tool
      @command_type = command_type
      @timer = Timer.new
    end

    def run
      timer.record_elapsed { format? ? format! : review! }

      print_tool_info
      print_results

      result.exit_status
    end

    def seed
      # Keep the same seed for each instance so re-running generates the same results as the failure.
      # Otherwise, re-running after the failure will change the seed and show different results.
      @seed ||= Random.rand(100_000)
    end

    private

    def format?
      command_type == :format
    end

    def batch?
      Reviewer.tools.current.size > 1
    end

    def shell_out(cmd)
      results = Open3.capture3(cmd)

      @result = Result.new(*results)
      @last_command_run = cmd
    end

    def prepare!
      tool.last_prepared_at = Time.current.utc
      timer.record_prep { shell_out(tool.preparation_command) }
    end

    def review!
      prepare! if tool.stale?
      verbosity = batch? ? :total_silence : :no_silence
      shell_out(tool.review_command(verbosity, seed: seed))
    end

    def format!
      return unless tool.format_command?

      shell_out(tool.format_command)
    end

    def output
      @output ||= Output.new(tool, last_command_run, result, timer)
    end

    def print_tool_info
      output.current_tool
    end

    def print_results
      success? ? handle_success : handle_failure
    end

    def success?
      result.success?(max_exit_status: tool.max_exit_status)
    end

    def existing_results?
      !result.stdout.blank?
    end

    def handle_success
      if batch?
        # It's a batch, so just show the benchark...
        output.benchmark
      elsif existing_results?
        # It's not a batch, so if we captured results, show them...
        output.current_results
      else
        # It's not a batch, but we don't have results, so we need to run again
        rerun_verbosely
      end
    end

    def handle_failure
      if result.executable_not_found?
        output.missing_executable_guidance
      elsif existing_results?
        output.exit_status
        output.current_results
      elsif result.terminated?
        output.exit_status
      elsif result.cannot_execute?
        output.exit_status
      else
        output.exit_status
        rerun_verbosely
      end
    end

    def rerun_verbosely
      # We're expicitly re-running it so we can show the output. So we explicitly use :no_silence
      output.raw { tool.review_command(:no_silence, seed: seed) }
    end
  end
end
