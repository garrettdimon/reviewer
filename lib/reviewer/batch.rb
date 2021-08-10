# frozen_string_literal: true

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    class UnrecognizedCommandError < ArgumentError; end

    attr_reader :command_type, :tools, :output, :results

    # Generates an instance of Batch for running multiple tools together
    # @param command_type [Symbol] the type of command to run for each tool. One of: :install,
    #   :prepare, :review, :format
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

    def run
      benchmark_batch do
        tools.each do |tool|
          runner = Runner.new(tool, command_type, strategy)
          runner.run

          # Record the exit status
          capture_results(runner)

          # If the tool fails, stop running other tools
          break unless runner.success?
        end
      end

      results
    end

    def self.run(*args)
      new(*args).run
    end

    private

    def multiple_tools?
      tools.size > 1
    end

    def strategy
      multiple_tools? ? Runner::Strategies::Quiet : Runner::Strategies::Verbose
    end

    def capture_results(runner)
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
    def benchmark_batch(&block)
      elapsed_time = Benchmark.realtime(&block)
      output.batch_summary(results.size, elapsed_time)
    end
  end
end
