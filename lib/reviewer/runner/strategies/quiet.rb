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
          runner.prepare_with_capture
        end

        def run
          runner.run_with_capture
          runner.show_results
        end
      end
    end
  end
end
