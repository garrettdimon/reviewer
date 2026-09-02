# frozen_string_literal: true

require_relative 'batch/formatter'

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    # Raised when a tool specifies an unrecognized command type
    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :command_type, :tools, :report, :context, :strategy
    private :context, :strategy

    # Generates an instance of Batch for running multiple tools together
    # @param command_type [Symbol] the type of command to run for each tool.
    # @param tools [Array<Tool>] the tools to run the commands for
    # @param strategy [Class] the runner strategy class (Captured or Passthrough)
    # @param context [Context] the shared runtime dependencies (arguments, output, history)
    #
    # @return [self]
    def initialize(command_type, tools, strategy:, context:)
      @command_type = command_type
      @tools = tools
      @strategy = strategy
      @context = context
      @report = Report.new
    end

    # Iterates over the tools in the batch to successfully run the commands. Also times the entire
    #   batch in order to provide a total execution time.
    #
    # @return [Report] the report containing results for all commands run
    def run
      runnable_tools = matching_tools
      elapsed_time = Benchmark.realtime do
        failed_index = runnable_tools.find_index { |tool| run_tool(tool).failed? }
        record_remaining(runnable_tools.drop(failed_index + 1)) if failed_index
      end

      @report.record_duration(elapsed_time)
      @report
    end

    private

    def record_remaining(tools)
      tools.each do |tool|
        if Command.new(tool, command_type, context: context).skip?
          run_tool(tool)
          next
        end

        result = Runner::Result.not_run(tool: tool, command_type: command_type)
        @report.add(result)
      end
    end

    # Runs a single tool and records its result in the report.
    # @return [Runner::Result] the recorded result
    def run_tool(tool)
      runner = Runner.new(tool, command_type, strategy, context: context)
      runner.run

      result = runner.to_result
      @report.add(result)
      tool.record_run(result)

      result
    end

    # Returns the set of tools matching the provided command. So when formatting, if a tool does not
    #   have a format command, then it will be skipped.
    #
    # @return [Array<Tool>] the enabled tools that support the provided command
    def matching_tools
      tools.select { |tool| tool.command?(command_type) }
    end
  end
end
