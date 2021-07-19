# frozen_string_literal: true

require 'open3'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    EXECUTABLE_NOT_FOUND_EXIT_STATUS_CODE = 127

    attr_accessor :tool, :command_type

    attr_reader :elapsed_time,
                :prep_time,
                :last_command_run,
                :stdout,
                :stderr,
                :status,
                :exit_status,
                :logger

    def initialize(tool, command_type, logger: Logger.new)
      @tool = tool
      @command_type = command_type
      @logger = logger
    end

    def run
      logger.running(tool)
      @elapsed_time = Benchmark.realtime { format? ? format! : review! }
      print_result
      exit_status
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
      @stdout, @stderr, @status = Open3.capture3(cmd)
      @exit_status = status.exitstatus
      @last_command_run = cmd
    end

    def prepare!
      tool.last_prepared_at = Time.current.utc
      @prep_time = Benchmark.realtime { shell_out(tool.preparation_command) }
    end

    def review!
      prepare! if tool.stale?
      verbosity = solo_tool_run? ? :no_silence : :total_silence
      shell_out(tool.review_command(verbosity, seed: seed))
    end

    def format!
      return unless tool.format_command?

      shell_out(tool.format_command) if tool.format_command?
    end

    def print_result
      if solo_tool_run? && status.success?
        show_tool_output
      elsif status.success?
        show_benchmark
      elsif missing_executable?
        show_missing_executable_guidance
      else
        show_failure_guidance
      end
    end

    def show_benchmark
      logger.success(elapsed_time, prep_time)
    end

    def show_missing_executable_guidance
      logger.failure("Missing executable for '#{tool}'")
      logger.last_command(last_command_run)
      logger.guidance('Try installing the tool:', tool.installation_command)
      logger.guidance('Read the installation guidance:', tool.settings.links&.fetch(:install, nil))
    end

    def show_failure_guidance
      logger.failure("Exit Status #{exit_status}")
      show_tool_output
    end

    def show_tool_output
      logger.output do
        stdout.blank? ? rerun_verbosely : show_stdout_results
      end

      logger.last_command(last_command_run)
    end

    def rerun_verbosely
      cmd = tool.review_command(:no_silence, seed: seed)
      logger.command("#{cmd}\n")
      system(cmd)
    end

    def show_stdout_results
      logger.info "\n#{stdout}"
    end

    def missing_executable?
      @exit_status == EXECUTABLE_NOT_FOUND_EXIT_STATUS_CODE ||
        stderr.include?("can't find executable")
    end
  end
end
