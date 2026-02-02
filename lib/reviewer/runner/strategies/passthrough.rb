# frozen_string_literal: true

module Reviewer
  class Runner
    module Strategies
      # Execution strategy for a runner to run a command transparently-displaying the command's
      #   output in realtime as it runs (as opposed to capturing and suppressing the output unless
      #   the command fails)
      # @attr_reader runner [Runner] the instance of the runner that will be executed with this strategy
      class Passthrough
        attr_reader :runner

        # Create an instance of the passthrough strategy for a command runner. This strategy ensures
        # that when a command is run, the output isn't suppressed. Essentially, it's a transparent
        # wrapper for running a command and displaying the results realtime.
        # @param runner [Runner] the instance of the runner to apply the strategy to
        #
        # @return [self]
        def initialize(runner)
          @runner = runner
        end

        # The prepare command strategy when running a command transparently
        #
        # @return [void]
        def prepare
          # Running the prepare command, so make sure the timestamp is updated
          runner.update_last_prepared_at

          # Display the exact command syntax that's being run. This can come in handy if there's an
          # issue and the command can be copied/pasted or if the generated command somehow has some
          # incorrect syntax or options that need to be corrected.
          runner.formatter.current_command(runner.prepare_command)

          # Run the command through the shell directly so no output is suppressed
          runner.shell.direct(runner.prepare_command)
        end

        # The run command strategy when running a command transparently
        #
        # @return [void]
        def run
          # Display the exact command syntax that's being run. This can come in handy if there's an
          # issue and the command can be copied/pasted or if the generated command somehow has some
          # incorrect syntax or options that need to be corrected.
          runner.formatter.current_command(runner.command)

          # Run the command through the shell directly so no output is suppressed
          runner.shell.direct(runner.command)
        end
      end
    end
  end
end
