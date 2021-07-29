# frozen_string_literal: true

module Reviewer
  # Provides a structure for running commands for a given set of tools
  class Batch
    attr_reader :tools, :command_type, :results

    def initialize(command_type, tools)
      @tools = tools
      @command_type = command_type
      @results = {}
    end

    def run
      tools.each do |tool|
        runner = Runner.new(tool, command_type, verbosity)

        # Do the thing
        runner.run

        # Record the exit status
        capture_results(runner)

        # If the tool fails, stop running other tools
        break unless runner.success?
      end

      results
    end

    def self.run(**kwargs)
      new(**kwargs).run
    end

    private

    def multiple_tools?
      tools.size > 1
    end

    def verbosity
      multiple_tools? ? :total_silence : :no_silence
    end

    def capture_results(runner)
      @results[runner.tool.key] = runner.exit_status
    end
  end
end
