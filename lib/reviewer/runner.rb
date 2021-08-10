# frozen_string_literal: true

require_relative 'runner/strategies/silent'
require_relative 'runner/strategies/verbose'

module Reviewer
  # Wrapper for executng a command and printing the results
  class Runner
    extend Forwardable

    attr_accessor :strategy

    attr_reader :command, :shell, :output

    def_delegators :@command, :tool
    def_delegators :@shell, :result, :timer
    def_delegators :result, :exit_status

    def initialize(tool, command_type, strategy = Strategies::Silent, output: Reviewer.output)
      @command = Command.new(tool, command_type)
      @strategy = strategy
      @shell = Shell.new
      @output = output
    end

    def run
      identify_tool

      execute_strategy

      # If it failed,
      guidance.show unless success?

      exit_status
    end

    def success?
      # Some review tools return a range of non-zero exit statuses and almost never return 0.
      # (`yarn audit` is a good example.) Those tools can be configured to accept a non-zero exit
      # status so they aren't constantly considered to be failing over minor issues.
      #
      # But when other command types (prepare, install, format) are run, they either succeed or they
      # fail. With no shades of gray in those cases, anything other than a 0 is a failure.
      if command.type == :review
        exit_status <= tool.max_exit_status
      else
        exit_status.zero?
      end
    end

    def identify_tool
      # If there's an existing result, the runner is being re-run, and identifying the tool would
      # be redundant.
      return if result.exists?

      output.tool_summary(tool)
    end

    def execute_strategy
      # Run the provided strategy
      strategy.new(self).tap do |run_strategy|
        run_strategy.prepare if run_prepare_step?
        run_strategy.run
      end
    end

    def run_prepare_step?
      command.type != :prepare && tool.prepare?
    end

    def prepare_command
      @prepare_command ||= Command.new(tool, :prepare, command.verbosity)
    end

    def update_last_prepared_at
      # Touch the `last_prepared_at` timestamp for the tool so it waits before running again.
      tool.last_prepared_at = Time.now
    end

    def guidance
      @guidance ||= Reviewer::Guidance.new(command: command, result: result, output: output)
    end
  end
end
