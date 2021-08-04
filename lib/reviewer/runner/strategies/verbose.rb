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
          runner.prepare_without_capture
        end

        def run
          runner.run_without_capture
        end
      end
    end
  end
end
