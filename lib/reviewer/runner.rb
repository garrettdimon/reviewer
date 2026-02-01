# frozen_string_literal: true

require_relative 'runner/failed_files'
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

    attr_reader :command, :shell, :output

    def_delegators :@command, :tool
    def_delegators :@shell, :result, :timer
    def_delegators :result, :exit_status, :stdout, :stderr, :rerunnable?

    # Creates a wrapper for running commansd through Reviewer in order to provide a more accessible
    #   API for recording execution time and interpreting the results of a command in a more
    #   generous way so that non-zero exit statuses can still potentiall be passing.
    # @param tool [Symbol] the key for the desired tool to run
    # @param command_type [Symbol] the key for the type of command to run
    # @param strategy = Strategies::Captured [Runner::Strategies] how to execute and handle the
    #   results of the command
    # @param output: Reviewer.output [Review::Output] the output formatter for the results
    #
    # @return [self]
    def initialize(tool, command_type, strategy = Strategies::Captured, output: Reviewer.output, arguments: Reviewer.arguments)
      @command = Command.new(tool, command_type, arguments: arguments)
      @strategy = strategy
      @shell = Shell.new
      @output = output
      @skipped = false
      @missing = false
      @streaming = arguments.streaming?
    end

    # Whether this runner is operating in streaming mode
    #
    # @return [Boolean] true if output should be streamed
    def streaming? = @streaming

    # Executes the command and returns the exit status
    #
    # @return [Integer] the exit status from the command
    def run
      # Skip if files were requested but none match this tool's pattern
      if command.skip?
        @skipped = true
        show_skipped if streaming?
        return 0
      end

      # Show which tool is running (only in streaming mode)
      identify_tool if streaming?

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

    # Prints the tool name and description to the console as a frame of reference
    #
    # @return [void]
    def identify_tool
      # If there's an existing result, the runner is being re-run, and identifying the tool would
      # be redundant.
      return if result.exists?

      output.tool_summary(tool)
    end

    # Shows that a tool was skipped due to no matching files
    #
    # @return [void]
    def show_skipped
      output.tool_summary(tool)
      output.skipped
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
    def prepare_command = @prepare_command ||= Command.new(tool, :prepare)

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
    def guidance = @guidance ||= Guidance.new(command: command, result: result, output: output)

    # Builds an immutable Result object from the current runner state
    #
    # @return [Runner::Result] the result of running this tool
    def to_result
      if skipped?
        skipped_result
      elsif missing?
        missing_result
      else
        executed_result
      end
    end

    private

    # Marks the tool as missing and shows a skip message
    #
    # @return [Integer] the exit status from the command
    def handle_missing
      @missing = true
      output.skipped('not installed') if streaming?
      exit_status
    end

    # Shows failure guidance if needed and returns the exit status
    #
    # @return [Integer] the exit status from the command
    def handle_result
      guidance.show if failure? && streaming?
      exit_status
    end

    # Result for a tool that was skipped due to no matching files
    #
    # @return [Runner::Result]
    def skipped_result
      Result.new(
        tool_key: tool.key,
        tool_name: tool.name,
        command_type: command.type,
        command_string: nil,
        success: true,
        exit_status: 0,
        duration: 0,
        stdout: nil,
        stderr: nil,
        skipped: true
      )
    end

    # Result for a tool whose executable was not found
    #
    # @return [Runner::Result]
    def missing_result
      Result.new(
        tool_key: tool.key,
        tool_name: tool.name,
        command_type: command.type,
        command_string: command.string,
        success: false,
        exit_status: exit_status,
        duration: 0,
        stdout: nil,
        stderr: nil,
        skipped: nil,
        missing: true
      )
    end

    # Result for a tool that was actually executed
    #
    # @return [Runner::Result]
    def executed_result
      Result.new(
        tool_key: tool.key,
        tool_name: tool.name,
        command_type: command.type,
        command_string: command.string,
        success: success?,
        exit_status: exit_status,
        duration: timer.total_seconds,
        stdout: stdout,
        stderr: stderr,
        skipped: nil
      )
    end
  end
end
