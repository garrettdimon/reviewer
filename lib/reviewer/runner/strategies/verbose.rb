# frozen_string_literal: true

module Reviewer
  class Runner
    module Strategies
      # Execution strategy to run a command verbosely
      class Verbose
        attr_accessor :runner

        def initialize(runner)
          @runner = runner
          @runner.command.verbosity = Reviewer::Command::Verbosity::NO_SILENCE
        end

        def prepare
          runner.update_last_prepared_at
          runner.output.current_command(runner.prepare_command)
          runner.output.divider
          runner.shell.direct(runner.prepare_command)
        end

        def run
          runner.output.current_command(runner.command)
          runner.output.divider
          runner.shell.direct(runner.command)
          runner.output.divider
        end
      end
    end
  end
end
