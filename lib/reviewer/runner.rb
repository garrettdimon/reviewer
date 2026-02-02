# frozen_string_literal: true

require_relative 'runner/failed_files'
require_relative 'runner/formatter'
require_relative 'runner/guidance'
require_relative 'runner/result'
require_relative 'runner/strategies/captured'
require_relative 'runner/strategies/passthrough'

module Reviewer
  # Wrapper for executng a command and printing the results
  class Runner
    extend Forwardable

    # @!attribute strategy
    #   @return [Class] the strategy class for running the command (Captured or Passthrough)
    attr_accessor :strategy

    attr_reader :command, :shell

    def_delegators :@command, :tool
    def_delegators :@shell, :result, :timer
    def_delegators :result, :exit_status, :stdout, :stderr, :rerunnable?

    # Creates a wrapper for running commands through Reviewer in order to provide a more accessible
    #   API for recording execution time and interpreting the results of a command in a more
    #   generous way so that non-zero exit statuses can still potentially be passing.
    # @param tool [Symbol] the key for the desired tool to run
    # @param command_type [Symbol] the key for the type of command to run
    # @param strategy [Runner::Strategies] how to execute and handle the results of the command
    # @param context [Context] the shared runtime dependencies (arguments, output, history)
    #
    # @return [self]
    def initialize(tool, command_type, strategy = Strategies::Captured, context:)
      @command = Command.new(tool, command_type, context: context)
      @strategy = strategy
      @shell = Shell.new
      @context = context
      @skipped = false
      @missing = false
    end

    # The output channel for displaying content, delegated from context.
    #
    # @return [Output]
    def output = @context.output

    # Display formatter for runner-specific output (tool summary, success, failure, etc.)
    # Computed rather than stored to avoid exceeding instance variable threshold.
    #
    # @return [Runner::Formatter]
    def formatter = @formatter ||= Runner::Formatter.new(output)

    # Whether this runner is operating in streaming mode
    #
    # @return [Boolean] true if output should be streamed
    def streaming? = @context.arguments.streaming?

    # Executes the command and returns the exit status
    #
    # @return [Integer] the exit status from the command
    def run
      # Skip if files were requested but none match this tool's pattern
      if command.skip?
        @skipped = true
        show_skipped
        return 0
      end

      # Show which tool is running
      identify_tool

      # Use the provided strategy to run the command
      execute_strategy

      # Handle the result based on whether the tool was found
      result.executable_not_found? ? handle_missing : handle_result
    end

    # Whether this runner was skipped due to no matching files
    #
    # @return [Boolean] true if the tool was skipped
    def skipped? = @skipped == true

    # Whether this runner's executable was not found (exit status 127)
    #
    # @return [Boolean] true if the tool was missing
    def missing? = @missing == true

    # Some review tools return a range of non-zero exit statuses and almost never return 0.
    # (`yarn audit` is a good example.) Those tools can be configured to accept a non-zero exit
    # status so they aren't constantly considered to be failing over minor issues.
    #
    # But when other command types (prepare, install, format) are run, they either succeed or they
    # fail. With no shades of gray in those cases, anything other than a 0 is a failure.
    #
    # Skipped tools are always considered successful.
    def success?
      return true if skipped?

      command.type == :review ? exit_status <= tool.max_exit_status : exit_status.zero?
    end

    def failure? = !success?

    # Extracts file paths from stdout/stderr for failed-file tracking
    #
    # @return [Array<String>] file paths found in the command output
    def failed_files
      FailedFiles.new(stdout, stderr).to_a
    end

    # Prints the tool name and description to the console as a frame of reference.
    # Only displays in streaming mode; non-streaming strategies handle their own output.
    #
    # @return [void]
    def identify_tool
      # If there's an existing result, the runner is being re-run, and identifying the tool would
      # be redundant.
      return if result.exists?

      stream_output { formatter.tool_summary(tool) }
    end

    # Shows that a tool was skipped due to no matching files.
    # Only displays in streaming mode; non-streaming modes report skips in the final summary.
    #
    # @return [void]
    def show_skipped
      stream_output do
        formatter.tool_summary(tool)
        formatter.skipped
      end
    end

    # Runs the relevant strategy to either capture or pass through command output.
    #
    # @return [void]
    def execute_strategy
      # Run the provided strategy
      strategy.new(self).tap do |run_strategy|
        run_strategy.prepare if run_prepare_step?
        run_strategy.run
      end
    end

    # Determines whether a preparation step should be run before the primary command. If/when the
    #   primary command is a `:prepare` command, then it shouldn't run twice. So it skips what would
    #   be a superfluous run of the preparation.
    #
    # @return [Boolean] true the primary command is not prepare and the tool needs to be prepare
    def run_prepare_step? = command.type != :prepare && tool.prepare?

    # Creates_an instance of the prepare command for a tool
    #
    # @return [Comman] the current tool's prepare command
    def prepare_command = @prepare_command ||= Command.new(tool, :prepare, context: @context)

    # Updates the 'last prepared at' timestamp that Reviewer uses to know if a tool's preparation
    #   step is stale and needs to be run again.
    #
    # @return [Time] the timestamp `last_prepared_at` is updated to
    def update_last_prepared_at = tool.last_prepared_at = Time.now

    # Saves the last 5 elapsed times for the commands used this run by using the raw command as a
    #   unique key. This enables the ability to compare times across runs while taking into
    #   consideration that different iterations of the command may be running on fewer files. So
    #   comparing a full run to the average time for a partial run wouldn't be helpful. By using the
    #   raw command string, it will always be apples to apples.
    #
    # @return [void]
    def record_timing
      tool.record_timing(prepare_command, timer.prep)
      tool.record_timing(command, timer.main)
    end

    # Uses the result of the runner to determine what, if any, guidance to display to help the user
    #   get back on track in the event of an unsuccessful run.
    #
    # @return [Guidance] the relevant guidance based on the result of the runner
    def guidance = @guidance ||= Guidance.new(command: command, result: result, context: @context)

    # Builds an immutable Result object from the current runner state
    #
    # @return [Runner::Result] the result of running this tool
    def to_result
      Result.from_runner(self)
    end

    private

    # Yields the block only when in streaming mode.
    # Centralizes the streaming guard so display methods don't each check independently.
    #
    # @return [void]
    def stream_output
      yield if streaming?
    end

    # Marks the tool as missing and shows a skip message
    #
    # @return [Integer] the exit status from the command
    def handle_missing
      @missing = true
      stream_output { formatter.skipped('not installed') }
      exit_status
    end

    # Shows failure guidance if needed and returns the exit status
    #
    # @return [Integer] the exit status from the command
    def handle_result
      stream_output { guidance.show } if failure?
      exit_status
    end
  end
end
