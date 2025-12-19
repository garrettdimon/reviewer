# frozen_string_literal: true

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :command_type, :tools, :output, :results

    # Generates an instance of Batch for running multiple tools together
    # @param command_type [Symbol] the type of command to run for each tool.
    # @param tools [Array<Tool>] the tools to run the commands for
    # @param output: Reviewer.output [Output] the output channel to print results to
    #
    # @return [self]
    def initialize(command_type, tools, output: Reviewer.output)
      @command_type = command_type
      @tools = tools
      @output  = output
      @results = {}
    end

    # Iterates over the tools in the batch to successfully run the commands. Also times the entire
    #   batch in order to provide a total execution time.
    #
    # @return [Results] the results summary for all commands run
    def run
      benchmark_batch do
        matching_tools.each do |tool|
          # Create and execute a runner for the given tool, command type, and strategy
          runner = Runner.new(tool, command_type, strategy)
          runner.run

          # Record the exit status for this tool
          record_exit_status(runner)

          # If the tool fails, stop running other tools
          break unless runner.success?
        end
      end

      results
    end

    private

    def multiple_tools?
      tools.size > 1
    end

    def strategy
      multiple_tools? ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
    end

    # Notes the exit status for the runner based on whether the runner was considered successful or
    #   not based on the configured `max_exit_status` for the tool. For example, some tools use exit
    #   status to convey significance. So even though it returns a non-zero exit status like 2, it
    #   can still be successful.
    # @param runner [Runner] the instance of the runner that's being inspected
    #
    # @return [Integer] the adjusted exit status for the runner
    def record_exit_status(runner)
      # Since some tools can "succeed" with a positive exit status, the overall batch is only
      # interested in subjective failure. So if the runner succeeded according to the tool's max
      # exit status, it should record the tool's run as a success for the purposes of the larger
      # batch success/failure
      @results[runner.tool.key] = runner.success? ? 0 : runner.exit_status
    end

    # Records and prints the total runtime of a block
    # @param &block [type] section of code to be timed
    #
    # @return [void] prints the elapsed time
    def benchmark_batch(&)
      elapsed_time = Benchmark.realtime(&)

      # If there's failures, skip showing the total time to focus on the issues
      return if @results.values.sum.positive?

      output.batch_summary(results.size, elapsed_time)
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
