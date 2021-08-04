# frozen_string_literal: true

module Reviewer
  class Runner
    module Strategies
      # Execution strategy to run a command quietly
      class Quiet
        attr_accessor :runner

        def initialize(runner)
          @runner = runner
          @runner.command.verbosity = Reviewer::Command::Verbosity::TOTAL_SILENCE
        end

        def prepare
          runner.update_last_prepared_at
          runner.shell.capture_prep(runner.prepare_command)
        end

        def run
          runner.shell.capture_main(runner.command)
          runner.success? ? show_timing_result : show_command_output
        end

        private

        def show_timing_result
          runner.output.success(runner.timer)
        end

        def show_command_output
          runner.output.failure("Exit Status #{runner.exit_status}", command: runner.command)

          # If it can't be rerun, then don't try
          return if runner.result.total_failure?

          # If it can be rerun, set the strategy to verbose so the output will be visible and run it
          runner.strategy = Strategies::Verbose
          runner.run
        end
      end
    end
  end
end
