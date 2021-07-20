# frozen_string_literal: true

require 'open3'

require_relative 'runner/result'
require_relative 'runner/timer'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    EXECUTABLE_NOT_FOUND_EXIT_STATUS_CODE = 127

    attr_accessor :tool, :command_type

    attr_reader :last_command_run,
                :timer,
                :result,
                :logger

    delegate :stdout,
             to: :result

    def initialize(tool, command_type, logger: Logger.new)
      @tool = tool
      @command_type = command_type
      @logger = logger
      @timer = Timer.new
    end

    def run
      logger.running(tool)
      timer.record_elapsed { format? ? format! : review! }
      print_result
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

    def solo_tool_run?
      Reviewer.tools.current.one?
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
      verbosity = solo_tool_run? ? :no_silence : :total_silence
      shell_out(tool.review_command(verbosity, seed: seed))
    end

    def format!
      return unless tool.format_command?

      shell_out(tool.format_command)
    end

    def print_result
      if result.success? && solo_tool_run?
        show_tool_output
      elsif result.success?
        show_benchmark
      elsif result.executable_not_found?
        show_missing_executable_guidance
      else
        show_failure_guidance
      end
    end

    def show_tool_output
      logger.output do
        result.stdout.blank? ? rerun_verbosely : show_stdout_results
      end

      logger.last_command(last_command_run)
    end

    def show_benchmark
      logger.success(timer)
    end

    def show_missing_executable_guidance
      logger.failure("Missing executable for '#{tool}'")
      logger.last_command(last_command_run)
      logger.guidance('Try installing the tool:', tool.installation_command)
      logger.guidance('Read the installation guidance:', tool.settings.links&.fetch(:install, nil))
    end

    def show_failure_guidance
      logger.failure("Exit Status #{result.exit_status}")
      show_tool_output
    end

    def rerun_verbosely
      cmd = tool.review_command(:no_silence, seed: seed)
      logger.command("#{cmd}\n")
      system(cmd)
    end

    def show_stdout_results
      logger.info "\n#{result}"
    end
  end
end
