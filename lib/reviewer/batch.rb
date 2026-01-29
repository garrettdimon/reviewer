# frozen_string_literal: true

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
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
        matching_tools.each do |tool|
          # Create and execute a runner for the given tool, command type, and strategy
          runner = Runner.new(tool, command_type, strategy)
          runner.run

          # Record the result for this tool
          @report.add(runner.to_result)

          # If the tool fails, stop running other tools
          break unless runner.success?
        end
      end

      @report.record_duration(elapsed_time)
      @report
    end

    private

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
