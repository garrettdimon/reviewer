# frozen_string_literal: true

require 'open3'

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    COMMAND_NOT_FOUND_EXIT_STATUS_CODE = 127

    attr_accessor :tool, :command

    attr_reader :elapsed_time, :stdout, :stderr, :status, :exit_status, :logger

    def initialize(tool, command, logger: Logger.new)
      @tool = tool
      @command = command
      @logger = logger
    end

    def run
      logger.running(tool)

      @elapsed_time = Benchmark.realtime do
        tool.format_command? ? run_format : run_review
      end

      print_result
      exit_status
    end

    private

    def shell_out(cmd)
      @stdout, @stderr, @status = Open3.capture3(cmd)
      @exit_status = status.exitstatus

      logger.command(cmd) unless status.success?
    end

    def run_review
      shell_out(tool.preparation_command) if tool.prepare_command?
      shell_out(tool.review_command(seed: seed))
    end

    def run_format
      shell_out(tool.format_command) if tool.format_command?
    end

    def review_verbosely
      cmd = tool.review_command(:no_silence, seed: seed)
      logger.rerunning(tool)
      logger.command(cmd)
      system(cmd)
    end

    def print_result
      if status.success?
        logger.success(elapsed_time)
      else
        recovery_guidance
      end
    end

    def recovery_guidance
      logger.failure(error_message)
      if missing_executable?
        missing_executable_guidance
      else
        review_verbosely
      end
    end

    def error_message
      if missing_executable?
        "Missing executable for '#{tool}'"
      else
        "Exit Status #{exit_status}"
      end
    end

    def missing_executable_guidance
      logger.guidance('Installation Command:', tool.installation_command) if tool.install_command?
      logger.guidance('Installation Help:', tool.settings.links[:install]) if tool.install_link?
    end

    def missing_executable?
      (@exit_status == COMMAND_NOT_FOUND_EXIT_STATUS_CODE) ||
        stderr.include?("can't find executable")
    end

    def seed
      # Keep the same seed for each instance so re-running generates the same results as the failure.
      # Otherwise, re-running after the failure will change the seed and show different results.
      @seed ||= Random.rand(100_000)
    end
  end
end
