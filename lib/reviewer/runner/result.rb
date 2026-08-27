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
    #   @return [String, nil] the full command string that was executed
    # @!attribute [r] state
    #   @return [Symbol] the canonical result state (:passed, :failed, :skipped, :missing, :not_run)
    # @!attribute [r] success
    #   @return [Boolean] compatibility value derived from state; true only for passed results
    # @!attribute [r] exit_status
    #   @return [Integer, nil] the exit status code from the command
    # @!attribute [r] duration
    #   @return [Float, nil] the execution time in seconds
    # @!attribute [r] stdout
    #   @return [String, nil] the standard output from the command
    # @!attribute [r] stderr
    #   @return [String, nil] the standard error from the command
    # @!attribute [r] skipped
    #   @return [Boolean, nil] compatibility value that is true only for skipped results
    # @!attribute [r] missing
    #   @return [Boolean, nil] compatibility value that is true only for missing results
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
      :summary_pattern,
      :summary_label,
      :state,
      keyword_init: true
    ) do
      # Freeze on initialization to maintain immutability like Data.define
      # :reek:FeatureEnvy -- validates the supplied compatibility values against canonical state
      # :reek:TooManyStatements -- compatibility is intentionally isolated in this initializer
      def initialize(state: nil, success: nil, skipped: nil, missing: nil, **attributes) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        state ||= if skipped
                    :skipped
                  elsif missing
                    :missing
                  elsif success == true
                    :passed
                  elsif success == false
                    :failed
                  end

        conflicting_flags = (skipped && state != :skipped) ||
                            (missing && state != :missing) ||
                            (skipped && missing)
        conflicting_success = (state == :passed && success == false) ||
                              (state == :failed && success == true)
        raise ArgumentError, 'Result state conflicts with legacy values' if conflicting_flags || conflicting_success

        super(**attributes, state: state, success: success, skipped: skipped, missing: missing)
        self[:success] = passed?
        self[:skipped] = true if skipped?
        self[:missing] = true if missing?
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

      # Builds a result for a tool that fail-fast prevented from running.
      # @param tool [Tool] the selected tool that did not run
      # @param command_type [Symbol] the requested command type
      #
      # @return [Result] an immutable not-run result
      def self.not_run(tool:, command_type:)
        new(
          tool_key: tool.key,
          tool_name: tool.name,
          command_type: command_type,
          command_string: nil,
          state: :not_run,
          exit_status: nil,
          duration: nil,
          stdout: nil,
          stderr: nil
        )
      end

      def self.base_attributes(runner)
        tool = runner.tool
        {
          tool_key: tool.key,
          tool_name: tool.name,
          command_type: runner.command.type,
          command_string: runner.command.string
        }
      end

      def self.build_skipped(runner)
        tool = runner.tool
        new(
          tool_key: tool.key,
          tool_name: tool.name,
          command_type: runner.command.type,
          command_string: nil,
          state: :skipped,
          exit_status: nil, duration: nil, stdout: nil, stderr: nil
        )
      end

      def self.build_missing(runner)
        new(
          **base_attributes(runner),
          state: :missing,
          exit_status: runner.shell.result.exit_status, duration: 0,
          stdout: nil, stderr: nil
        )
      end

      def self.build_executed(runner)
        shell = runner.shell
        shell_result = shell.result
        settings = runner.tool.settings
        new(
          **base_attributes(runner),
          state: runner.success? ? :passed : :failed,
          exit_status: shell_result.exit_status,
          duration: shell.timer.total_seconds,
          stdout: shell_result.stdout, stderr: shell_result.stderr,
          summary_pattern: settings.summary_pattern,
          summary_label: settings.summary_label
        )
      end

      private_class_method :base_attributes, :build_skipped, :build_missing, :build_executed

      def passed? = state?(:passed)
      def failed? = state?(:failed)
      def not_run? = state?(:not_run)
      alias_method :success, :passed?

      def skipped
        true if state?(:skipped)
      end

      def missing
        true if state?(:missing)
      end

      def success? = success
      def skipped? = skipped
      def missing? = missing

      def state?(value) = state == value
      private :state?

      # Whether this result represents a tool that actually ran
      #
      # @return [Boolean] true if the tool was executed
      def executed? = passed? || failed?

      # Extracts a short summary detail from stdout for display purposes.
      # Each tool type may have its own summary format (test count, offense count, etc.)
      #
      # @return [String, nil] a brief summary or nil if no detail can be extracted
      def detail_summary
        return nil unless summary_pattern

        match = stdout&.match(/#{summary_pattern}/i)
        return nil unless match

        summary_label.gsub(/\\(\d+)/) { match[Regexp.last_match(1).to_i] }
      end

      # Converts the result to a hash suitable for serialization
      #
      # @return [Hash] serialized result; skipped and not-run execution fields remain explicit nils
      def to_h # rubocop:disable Metrics/AbcSize
        attributes = {
          tool: tool_key,
          name: tool_name,
          command_type: command_type,
          command: command_string,
          state: state,
          success: success,
          exit_status: exit_status,
          duration: duration,
          stdout: stdout,
          stderr: stderr,
          skipped: skipped,
          missing: missing
        }

        return attributes.compact unless skipped? || not_run?

        attributes.compact.merge(attributes.slice(:command, :exit_status, :duration, :stdout, :stderr))
      end
    end
  end
end
