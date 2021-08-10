# frozen_string_literal: true

module Reviewer
  class Runner
    module Strategies
      # Execution strategy for a runner to run a command quietly
      class Silent
        attr_accessor :runner

        # Create an instance of the quiet strategy for a command runner so that any output is fully
        # suppressed so as to not create too much noise when running multiple commands.
        # @param runner [Runner] the instance of the runner to apply the strategy to
        #
        # @return [Runner::Strategies::Silent] an instance of the relevant quiet strategy
        def initialize(runner)
          @runner = runner
          @runner.command.verbosity = Reviewer::Command::Verbosity::SILENT
        end

        # The prepare command strategy when running a command quietly
        #
        # @return [void]
        def prepare
          # Running the prepare command, so make sure the timestamp is updated
          runner.update_last_prepared_at

          # Run the prepare command, suppressing the output and capturing the realtime benchmark
          runner.shell.capture_prep(runner.prepare_command)
        end

        # The run command strategy when running a command verbosely
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
        def show_command_output
          runner.output.failure("Exit Status #{runner.exit_status}", command: runner.command)

          # If it can't be rerun, then don't try
          return if runner.result.total_failure?

          # If it can be rerun, set the strategy to verbose so the output will be visible, and then
          # run it with the verbose strategy so the output isn't suppressed. Long-term, it makes
          # sense to add an option for whether to focus on speed or rich output.
          #
          # For now, the simplest strategy is to re-run the exact same command without suppressing
          # the output. However, running a command twice isn't exactly efficient. Since we've
          # already run it once and captured the output, we could just display that output, but it
          # would be filtered through as a dumb string. That would mean it strips out color and
          # formatting. It would save time, but what's the threshold where the time savings is worth
          # it?
          #
          # Ultimately, this will be a tradeoff between how much the tool's original formatting
          # makes it easier to scan the results and take action. For example, if a command takes
          # 60 seconds to run, it might be faster to show the low-fidelity output immediately rather
          # than waiting another 60 seconds for higher-fidelity output.
          #
          # Most likely, this will be a tool-by-tool decision and need to be added as an option to
          # the tool configuration, but that will create additional complexity/overhead when adding
          # a new tool.
          #
          # So for now, we punt. And pay close attention.
          runner.strategy = Strategies::Verbose
          runner.run
        end
      end
    end
  end
end
