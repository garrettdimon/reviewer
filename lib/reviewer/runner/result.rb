# frozen_string_literal: true

module Reviewer
  class Runner
    # Immutable value object representing the result of running a single tool
    #
    # @!attribute [r] tool_key
    #   @return [Symbol] the unique identifier for the tool
    # @!attribute [r] tool_name
    #   @return [String] the human-readable name of the tool
    # @!attribute [r] command_type
    #   @return [Symbol] the type of command run (:review, :format, etc.)
    # @!attribute [r] command_string
    #   @return [String] the full command string that was executed
    # @!attribute [r] success
    #   @return [Boolean] whether the command completed successfully
    # @!attribute [r] exit_status
    #   @return [Integer] the exit status code from the command
    # @!attribute [r] duration
    #   @return [Float] the execution time in seconds
    # @!attribute [r] stdout
    #   @return [String, nil] the standard output from the command
    # @!attribute [r] stderr
    #   @return [String, nil] the standard error from the command
    # @!attribute [r] skipped
    #   @return [Boolean] whether the tool was skipped
    # @!attribute [r] missing
    #   @return [Boolean] whether the tool's executable was not found
    Result = Struct.new(
      :tool_key,
      :tool_name,
      :command_type,
      :command_string,
      :success,
      :exit_status,
      :duration,
      :stdout,
      :stderr,
      :skipped,
      :missing,
      keyword_init: true
    ) do
      # Freeze on initialization to maintain immutability like Data.define
      def initialize(...)
        super
        freeze
      end

      # Builds an immutable Result from a runner's current state.
      # @param runner [Runner] the runner after command execution
      #
      # @return [Result] an immutable result for reporting
      def self.from_runner(runner)
        if runner.skipped?
          build_skipped(runner)
        elsif runner.missing?
          build_missing(runner)
        else
          build_executed(runner)
        end
      end

      def self.build_skipped(runner)
        new(
          tool_key: runner.tool.key, tool_name: runner.tool.name,
          command_type: runner.command.type, command_string: nil,
          success: true, exit_status: 0, duration: 0,
          stdout: nil, stderr: nil, skipped: true
        )
      end

      def self.build_missing(runner)
        new(
          tool_key: runner.tool.key, tool_name: runner.tool.name,
          command_type: runner.command.type, command_string: runner.command.string,
          success: false, exit_status: runner.shell.result.exit_status, duration: 0,
          stdout: nil, stderr: nil, skipped: nil, missing: true
        )
      end

      def self.build_executed(runner)
        tool = runner.tool
        command = runner.command
        shell = runner.shell
        result = shell.result
        new(
          tool_key: tool.key, tool_name: tool.name,
          command_type: command.type, command_string: command.string,
          success: runner.success?, exit_status: result.exit_status,
          duration: shell.timer.total_seconds,
          stdout: result.stdout, stderr: result.stderr, skipped: nil
        )
      end

      private_class_method :build_skipped, :build_missing, :build_executed

      alias_method :success?, :success
      alias_method :skipped?, :skipped
      alias_method :missing?, :missing

      # Whether this result represents a tool that actually ran (not skipped or missing)
      #
      # @return [Boolean] true if the tool was executed
      def executed? = !skipped? && !missing?

      # Extracts a short summary detail from stdout for display purposes.
      # Each tool type may have its own summary format (test count, offense count, etc.)
      #
      # @return [String, nil] a brief summary or nil if no detail can be extracted
      def detail_summary
        case tool_key
        when :tests
          match = stdout&.match(/(\d+)\s+tests?/i)
          match ? "#{match[1]} tests" : nil
        when :rubocop
          match = stdout&.match(/(\d+)\s+offenses?/i)
          match ? "#{match[1]} offenses" : nil
        end
      end

      # Converts the result to a hash suitable for serialization
      #
      # @return [Hash] hash representation with nil values removed
      def to_h
        {
          tool: tool_key,
          name: tool_name,
          command_type: command_type,
          command: command_string,
          success: success,
          exit_status: exit_status,
          duration: duration,
          stdout: stdout,
          stderr: stderr,
          skipped: skipped,
          missing: missing
        }.compact
      end
    end
  end
end
