# frozen_string_literal: true

module Reviewer
  class Runner
    module Strategies
      # Execution strategy for a runner to run a command quietly by capturing the output and only
      #   displaying it if there's a failure that justifies it
      class Captured
        attr_accessor :runner

        # Create an instance of the captured strategy for a command runner so that any output is
        #    fully suppressed so as to not create too much noise when running multiple commands.
        # @param runner [Runner] the instance of the runner to apply the strategy to
        #
        # @return [self]
        def initialize(runner)
          @runner = runner
        end

        # The prepare command strategy when running a command and capturing the results
        #
        # @return [void]
        def prepare
          # Running the prepare command, so make sure the timestamp is updated
          runner.update_last_prepared_at

          # Run the prepare command, suppressing the output and capturing the realtime benchmark
          runner.shell.capture_prep(runner.prepare_command)
        end

        # The run command strategy when running a command and capturing the results
        #
        # @return [void]
        def run
          # Run the primary command, suppressing the output and capturing the realtime benchmark
          runner.shell.capture_main(runner.command)

          # If it's successful, show that it was a success and how long it took to run, otherwise,
          # it wasn't successful and we got some explaining to do...
          runner.success? ? show_timing_result : show_command_output
        end

        private

        # Prints "Success" and the resulting timing details before moving on to the next tool
        #
        # @return [void]
        def show_timing_result
          runner.output.success(runner.timer)
        end

        # Prints "Failure" and the resulting exit status. Shows the precise command that led to the
        # failure for easier copy and paste or making it easier to see any incorrect syntax or
        # options that could be corrected.
        #
        # @return [void]
        def show_command_output # rubocop:disable Metrics/AbcSize
          # If there's a failure, clear the successful command output to focus on the issues
          runner.output.clear

          # Show the exit status and failed command
          runner.output.failure("Exit Status #{runner.exit_status}", command: runner.command)

          # Delineate the reviewer output from the command's raw output
          runner.output.divider
          runner.output.newline

          # If it can't be rerun, then don't try
          runner.output? ? show_captured_output : rerun_via_passthrough

          # Delineate the end of the raw output from any additional guidance displayed by reviewer
          runner.output.divider
        end

        # If the command sent output to stdout/stderr as most will, simply display what was captured
        #
        # @return [void]
        def show_captured_output
          runner.output.unfiltered(runner.result.stdout)

          return if (runner.result.stderr.nil? || runner.result.stderr.empty?)

          runner.output.divider
          runner.output.newline
          runner.output.guidance('Runtime Errors:', runner.result.stderr)
        end

        # If for some reason, the command didn't send anything to stdout/stderr, the only option to
        # show results is to rerun it via the passthrough strategy
        #
        # @return [void]
        def rerun_via_passthrough
          return unless runner.rerunnable?

          runner.strategy = Strategies::Passthrough
          runner.run
        end
      end
    end
  end
end
