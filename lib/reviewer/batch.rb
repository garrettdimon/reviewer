# frozen_string_literal: true

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    # Raised when a tool specifies an unrecognized command type
    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :command_type, :tools, :report

    # Generates an instance of Batch for running multiple tools together
    # @param command_type [Symbol] the type of command to run for each tool.
    # @param tools [Array<Tool>] the tools to run the commands for
    #
    # @return [self]
    def initialize(command_type, tools)
      @command_type = command_type
      @tools = tools
      @report = Report.new
    end

    # Iterates over the tools in the batch to successfully run the commands. Also times the entire
    #   batch in order to provide a total execution time.
    #
    # @return [Report] the report containing results for all commands run
    def run
      elapsed_time = Benchmark.realtime do
        # Clear stale statuses so tools that don't run (due to early break) aren't left
        # with a stale "failed" status from a prior run
        clear_last_statuses

        matching_tools.each do |tool|
          runner = Runner.new(tool, command_type, strategy)
          runner.run

          @report.add(runner.to_result)
          record_run(tool, runner) unless runner.missing?

          break unless runner.success? || runner.missing?
        end
      end

      @report.record_duration(elapsed_time)
      @report
    end

    private

    def clear_last_statuses
      history = Reviewer.history
      matching_tools.each do |tool|
        history.set(tool.key, :last_status, nil)
      end
    end

    # Records pass/fail status and failed files for the `failed` keyword to use on subsequent runs
    def record_run(tool, runner)
      success = runner.success?
      Reviewer.history.set(tool.key, :last_status, success ? :passed : :failed)

      if success
        Reviewer.history.set(tool.key, :last_failed_files, nil)
      else
        store_failed_files(tool, runner)
      end
    end

    # Passes stdout and stderr separately to FailedFiles, which merges them
    # internally when scanning for file paths. Only called for tools that failed
    # (exit status exceeded the tool's max_exit_status threshold).
    def store_failed_files(tool, runner)
      files = Runner::FailedFiles.new(runner.stdout, runner.stderr).to_a
      Reviewer.history.set(tool.key, :last_failed_files, files) if files.any?
    end

    def multiple_tools? = tools.size > 1

    def strategy
      args = Reviewer.arguments
      return Runner::Strategies::Passthrough if args.raw?
      return Runner::Strategies::Captured unless args.streaming?

      multiple_tools? ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
    end

    # Returns the set of tools matching the provided command. So when formatting, if a tool does not
    #   have a format command, then it will be skipped.
    #
    # @return [Array<Tool>] the enabled tools that support the provided command
    def matching_tools
      tools.select { |tool| tool.settings.commands.key?(command_type) }
    end
  end
end
