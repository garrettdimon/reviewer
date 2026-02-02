# frozen_string_literal: true

require_relative 'batch/formatter'

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    # Raised when a tool specifies an unrecognized command type
    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :command_type, :tools, :report, :context
    private :context

    # Generates an instance of Batch for running multiple tools together
    # @param command_type [Symbol] the type of command to run for each tool.
    # @param tools [Array<Tool>] the tools to run the commands for
    # @param context [Context] the shared runtime dependencies (arguments, output, history)
    #
    # @return [self]
    def initialize(command_type, tools, context:)
      @command_type = command_type
      @tools = tools
      @context = context
      @report = Report.new
    end

    # Iterates over the tools in the batch to successfully run the commands. Also times the entire
    #   batch in order to provide a total execution time.
    #
    # @return [Report] the report containing results for all commands run
    def run
      elapsed_time = Benchmark.realtime do
        clear_last_statuses
        matching_tools.each do |tool|
          runner = run_tool(tool)
          break unless runner.success? || runner.missing?
        end
      end

      @report.record_duration(elapsed_time)
      @report
    end

    private

    # Runs a single tool and records its result in the report.
    # @return [Runner] the runner after execution
    def run_tool(tool)
      runner = Runner.new(tool, command_type, strategy, context: context)
      runner.run

      @report.add(runner.to_result)
      record_run(tool, runner) unless runner.missing?

      runner
    end

    def clear_last_statuses
      matching_tools.each do |tool|
        context.history.set(tool.key, :last_status, nil)
      end
    end

    # Records pass/fail status and failed files for the `failed` keyword to use on subsequent runs
    def record_run(tool, runner)
      success = runner.success?
      context.history.set(tool.key, :last_status, success ? :passed : :failed)

      if success
        context.history.set(tool.key, :last_failed_files, nil)
      else
        store_failed_files(tool, runner)
      end
    end

    # Extracts failed file paths from the runner's output and stores them
    # in history for the `failed` keyword to use on subsequent runs.
    def store_failed_files(tool, runner)
      files = runner.failed_files
      context.history.set(tool.key, :last_failed_files, files) if files.any?
    end

    # Determines the runner strategy based on CLI flags and tool count
    #
    # @return [Class] the strategy class (Captured or Passthrough)
    def strategy
      context.arguments.runner_strategy(multiple_tools: tools.size > 1)
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
