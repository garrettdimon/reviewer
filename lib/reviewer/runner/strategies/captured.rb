# frozen_string_literal: true

module Reviewer
  class Runner
    module Strategies
      # Execution strategy for a runner to run a command quietly by capturing the output and only
      #   displaying it if there's a failure that justifies it
      class Captured
        attr_accessor :runner

        attr_reader :start_time

        # Create an instance of the captured strategy for a command runner so that any output is
        #    fully suppressed so as to not create too much noise when running multiple commands.
        # @param runner [Runner] the instance of the runner to apply the strategy to
        #
        # @return [self]
        def initialize(runner)
          @runner = runner
          @start_time = Time.now
        end

        # The prepare command strategy when running a command and capturing the results
        #
        # @return [void]
        def prepare
          command = runner.prepare_command

          display_progress(command) { runner.shell.capture_prep(command) }

          # Running the prepare command, so make sure the timestamp is updated
          runner.update_last_prepared_at
        end

        # The run command strategy when running a command and capturing the results
        #
        # @return [void]
        def run
          command = runner.command

          display_progress(command) { runner.shell.capture_main(command) }

          # If it's successful, show that it was a success and how long it took to run, otherwise,
          # it wasn't successful and we got some explaining to do...
          runner.success? ? show_timing_result : show_command_output
        end

        private

        def display_progress(command, &block)
          start_time = Time.now
          average_time = runner.tool.average_time(command)

          thread = Thread.new { block.call }

          while thread.alive?
            elapsed = (Time.now - start_time).to_f.round(1)
            progress = if average_time.zero?
                         "#{elapsed}s"
                       else
                         "~#{((elapsed / average_time) * 100).round}%"
                       end

            $stdout.print "> #{progress}\r"
            $stdout.flush
          end
        end

        def usable_output_captured?
          [runner.stdout, runner.stderr].reject { |value| value.nil? || value.strip.empty? }.any?
        end

        # Prints "Success" and the resulting timing details before moving on to the next tool
        #
        # @return [void]
        def show_timing_result
          runner.record_timing
          runner.output.success(runner.timer)
        end

        # Prints "Failure" and the resulting exit status. Shows the precise command that led to the
        # failure for easier copy and paste or making it easier to see any incorrect syntax or
        # options that could be corrected.
        #
        # @return [void]
        def show_command_output
          # If there's a failure, clear the successful command output to focus on the issues
          runner.output.clear

          # Show the exit status and failed command
          runner.output.failure("Exit Status #{runner.exit_status}", command: runner.command)

          # If it can't be rerun, then don't try
          usable_output_captured? ? show_captured_output : rerun_via_passthrough
        end

        # If the command sent output to stdout/stderr as most will, simply display what was captured
        #
        # @return [void]
        def show_captured_output
          show_captured_stdout
          show_captured_stderr
        end

        # If there's a useful stdout value, display it with a divider to visually separate it.
        #
        # @return [void]
        def show_captured_stdout
          return if runner.stdout.nil? || runner.stdout.empty?

          runner.output.divider
          runner.output.newline
          runner.output.unfiltered(runner.stdout)
        end

        # If there's a useful stderr value, display it with a divider to visually separate it.
        #
        # @return [void]
        def show_captured_stderr
          return if runner.stderr.nil? || runner.stderr.empty?

          scrubbed_stderr = Reviewer::Output::Scrubber.new(runner.stderr).clean

          runner.output.divider
          runner.output.newline
          runner.output.guidance('Runtime Errors:', scrubbed_stderr)
        end

        # If for some reason, the command didn't send anything to stdout/stderr, the only option to
        # show results is to rerun it via the passthrough strategy
        #
        # @return [void]
        def rerun_via_passthrough
          return unless runner.rerunnable?

          runner.strategy = Strategies::Passthrough

          runner.output.divider
          runner.run
        end
      end
    end
  end
end
