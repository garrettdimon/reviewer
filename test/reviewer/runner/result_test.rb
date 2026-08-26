# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    class ResultTest < Minitest::Test
      def setup
        @result = Result.new(
          tool_key: :rubocop,
          tool_name: 'RuboCop',
          command_type: :review,
          command_string: 'bundle exec rubocop',
          success: true,
          exit_status: 0,
          duration: 5.2,
          stdout: 'Inspecting 42 files',
          stderr: nil,
          skipped: nil
        )
      end

      def test_exposes_tool_attributes
        assert_equal :rubocop, @result.tool_key
        assert_equal 'RuboCop', @result.tool_name
      end

      def test_exposes_command_attributes
        assert_equal :review, @result.command_type
        assert_equal 'bundle exec rubocop', @result.command_string
      end

      def test_exposes_execution_attributes
        assert @result.success
        assert_equal 0, @result.exit_status
        assert_equal 5.2, @result.duration
      end

      def test_exposes_output_attributes
        assert_equal 'Inspecting 42 files', @result.stdout
        assert_nil @result.stderr
      end

      def test_to_h_maps_tool_keys
        hash = @result.to_h
        assert_equal :rubocop, hash[:tool]
        assert_equal 'RuboCop', hash[:name]
      end

      def test_to_h_includes_state
        assert_equal :passed, @result.to_h[:state]
      end

      def test_to_h_maps_command_keys
        hash = @result.to_h
        assert_equal :review, hash[:command_type]
        assert_equal 'bundle exec rubocop', hash[:command]
      end

      def test_to_h_maps_execution_keys
        hash = @result.to_h
        assert hash[:success]
        assert_equal 0, hash[:exit_status]
        assert_equal 5.2, hash[:duration]
        assert_equal 'Inspecting 42 files', hash[:stdout]
      end

      def test_to_h_excludes_nil_values
        result = Result.new(
          tool_key: :tests,
          tool_name: 'Tests',
          command_type: :review,
          command_string: 'rake test',
          success: true,
          exit_status: 0,
          duration: 3.1,
          stdout: nil,
          stderr: nil,
          skipped: nil
        )

        hash = result.to_h

        refute hash.key?(:stdout)
        refute hash.key?(:stderr)
        refute hash.key?(:skipped)
      end

      def test_failed_result
        result = Result.new(
          tool_key: :tests,
          tool_name: 'Tests',
          command_type: :review,
          command_string: 'rake test',
          success: false,
          exit_status: 1,
          duration: 2.5,
          stdout: '1 failure',
          stderr: 'Error details',
          skipped: nil
        )

        refute result.success
        assert_equal 1, result.exit_status
        assert_equal '1 failure', result.stdout
        assert_equal 'Error details', result.stderr
      end

      def test_missing_field_defaults_to_nil
        assert_nil @result.missing
      end

      def test_missing_result_exposes_missing_field
        result = Result.new(
          tool_key: :rubocop,
          tool_name: 'RuboCop',
          command_type: :review,
          command_string: nil,
          success: false,
          exit_status: 127,
          duration: 0,
          stdout: nil,
          stderr: nil,
          skipped: nil,
          missing: true
        )

        assert result.missing
      end

      def test_to_h_includes_missing_when_true
        result = Result.new(
          tool_key: :rubocop,
          tool_name: 'RuboCop',
          command_type: :review,
          command_string: nil,
          success: false,
          exit_status: 127,
          duration: 0,
          stdout: nil,
          stderr: nil,
          skipped: nil,
          missing: true
        )

        assert result.to_h[:missing]
      end

      def test_to_h_excludes_missing_when_nil
        refute @result.to_h.key?(:missing)
      end

      def test_to_h_keeps_null_execution_fields_for_skipped_result
        hash = build_via_from_runner(skipped: true).to_h

        %i[command exit_status duration stdout stderr].each do |key|
          assert hash.key?(key), "Expected #{key} to be present"
          assert_nil hash[key]
        end
      end

      def test_success_predicate
        assert @result.success?
      end

      def test_success_predicate_when_false
        result = Result.new(
          tool_key: :tests, tool_name: 'Tests', command_type: :review,
          command_string: 'rake test', success: false, exit_status: 1,
          duration: 2.5, stdout: nil, stderr: nil, skipped: nil
        )

        refute result.success?
      end

      def test_state_construction_derives_compatibility_values
        result = Result.new(
          tool_key: :tests, tool_name: 'Tests', command_type: :review,
          command_string: nil, state: :skipped, exit_status: nil,
          duration: nil, stdout: nil, stderr: nil
        )

        refute result.success
        assert result.skipped
        assert_nil result.missing
      end

      def test_not_run_factory_builds_an_unexecuted_result
        result = Result.not_run(tool: build_tool(:enabled_tool), command_type: :review)

        expected = [:enabled_tool, 'Enabled Test Tool', :review, :not_run]
        assert_equal expected, [result.tool_key, result.tool_name, result.command_type, result.state]
        assert_equal [true, false, false, nil, nil, true], [
          result.not_run?, result.executed?, result.success,
          result.skipped, result.missing, result.frozen?
        ]

        assert_null_execution_data(result)
      end

      def test_legacy_construction_derives_state
        assert_equal :passed, @result.state
      end

      def test_rejects_state_that_conflicts_with_legacy_flags
        assert_raises(ArgumentError) do
          Result.new(
            tool_key: :tests, tool_name: 'Tests', command_type: :review,
            command_string: nil, state: :passed, success: true,
            exit_status: nil, duration: nil, stdout: nil, stderr: nil,
            skipped: true
          )
        end
      end

      def test_rejects_multiple_legacy_states
        assert_raises(ArgumentError) do
          Result.new(
            tool_key: :tests, tool_name: 'Tests', command_type: :review,
            command_string: nil, success: false, exit_status: nil,
            duration: nil, stdout: nil, stderr: nil,
            skipped: true, missing: true
          )
        end
      end

      def test_rejects_state_that_conflicts_with_legacy_success
        assert_raises(ArgumentError) do
          Result.new(
            tool_key: :tests, tool_name: 'Tests', command_type: :review,
            command_string: 'rake test', state: :passed, success: false,
            exit_status: 1, duration: 1, stdout: nil, stderr: nil
          )
        end
      end

      def test_skipped_predicate
        result = Result.new(
          tool_key: :tests, tool_name: 'Tests', command_type: :review,
          command_string: nil, success: false, exit_status: 0,
          duration: 0, stdout: nil, stderr: nil, skipped: true
        )

        assert result.skipped?
      end

      def test_skipped_predicate_when_nil
        refute @result.skipped?
      end

      def test_missing_predicate
        result = Result.new(
          tool_key: :rubocop, tool_name: 'RuboCop', command_type: :review,
          command_string: nil, success: false, exit_status: 127,
          duration: 0, stdout: nil, stderr: nil, skipped: nil, missing: true
        )

        assert result.missing?
      end

      def test_missing_predicate_when_nil
        refute @result.missing?
      end

      def test_result_is_immutable
        assert_raises(FrozenError) do
          @result.instance_variable_set(:@tool_key, :other)
        end
      end

      def test_executed_when_not_skipped_or_missing
        assert @result.executed?
      end

      def test_not_executed_when_skipped
        result = Result.new(
          tool_key: :tests, tool_name: 'Tests', command_type: :review,
          command_string: nil, success: true, exit_status: 0,
          duration: 0, stdout: nil, stderr: nil, skipped: true
        )

        refute result.executed?
      end

      def test_not_executed_when_missing
        result = Result.new(
          tool_key: :rubocop, tool_name: 'RuboCop', command_type: :review,
          command_string: nil, success: false, exit_status: 127,
          duration: 0, stdout: nil, stderr: nil, skipped: nil, missing: true
        )

        refute result.executed?
      end

      def test_detail_summary_for_tests
        result = Result.new(
          tool_key: :tests, tool_name: 'Minitest', command_type: :review,
          command_string: 'rake', success: true, exit_status: 0,
          duration: 1.0, stdout: '571 tests with 1290 assertions', stderr: nil, skipped: nil,
          summary_pattern: '(\d+)\s+tests?', summary_label: '\1 tests'
        )

        assert_equal '571 tests', result.detail_summary
      end

      def test_detail_summary_for_rubocop
        result = Result.new(
          tool_key: :rubocop, tool_name: 'RuboCop', command_type: :review,
          command_string: 'rubocop', success: false, exit_status: 1,
          duration: 1.0, stdout: '115 files inspected, 3 offenses detected', stderr: nil, skipped: nil,
          summary_pattern: '(\d+)\s+offenses?', summary_label: '\1 offenses'
        )

        assert_equal '3 offenses', result.detail_summary
      end

      def test_detail_summary_returns_nil_when_no_pattern
        result = Result.new(
          tool_key: :reek, tool_name: 'Reek', command_type: :review,
          command_string: 'reek', success: true, exit_status: 0,
          duration: 1.0, stdout: '0 total warnings', stderr: nil, skipped: nil
        )

        assert_nil result.detail_summary
      end

      def test_detail_summary_returns_nil_when_no_match
        result = Result.new(
          tool_key: :tests, tool_name: 'Minitest', command_type: :review,
          command_string: 'rake', success: true, exit_status: 0,
          duration: 1.0, stdout: nil, stderr: nil, skipped: nil,
          summary_pattern: '(\d+)\s+tests?', summary_label: '\1 tests'
        )

        assert_nil result.detail_summary
      end

      def test_from_runner_builds_skipped_result
        result = build_via_from_runner(skipped: true)

        assert_equal :skipped, result.state
        assert result.skipped
        refute result.success
        assert_null_execution_data(result)
      end

      def test_skipped_result_does_not_record_a_seed
        history = Reviewer.history
        history.set(:dynamic_seed_tool, :last_seed, nil)
        context = default_context(history: history)

        build_via_from_runner(skipped: true, tool_key: :dynamic_seed_tool, context: context)

        assert_nil history.get(:dynamic_seed_tool, :last_seed)
      ensure
        history&.set(:dynamic_seed_tool, :last_seed, nil)
      end

      def test_from_runner_builds_missing_result
        result = build_via_from_runner(missing: true)

        assert_equal :missing, result.state
        assert result.missing
        refute result.success
        assert_equal 127, result.exit_status
        assert_equal 0, result.duration
      end

      def test_from_runner_builds_executed_result
        result = build_via_from_runner

        assert_equal :passed, result.state
        assert_predicate result, :passed?
        refute result.skipped
        assert result.success
        assert_equal 0, result.exit_status
        assert_equal 3.5, result.duration
        assert_equal 'stdout', result.stdout
        assert_equal 'stderr', result.stderr
      end

      def test_from_runner_builds_failed_result
        result = build_via_from_runner(success: false, exit_status: 1)

        assert_equal :failed, result.state
        assert_respond_to result, :failed?
        assert_predicate result, :failed?
        refute result.success
        assert_equal 1, result.exit_status
      end

      RunnerDouble = Struct.new(:tool, :command, :shell, :skipped, :missing, :success, keyword_init: true) do
        def skipped? = skipped
        def missing? = missing
        def success? = success
      end

      private

      def assert_null_execution_data(result)
        hash = result.to_h
        %i[command exit_status duration stdout stderr].each do |key|
          assert hash.key?(key), "Expected #{key} to be present"
          assert_nil hash[key]
        end
      end

      def build_via_from_runner(skipped: false, missing: false, success: true, exit_status: nil,
                                tool_key: :enabled_tool, context: default_context)
        tool = build_tool(tool_key)
        command = Command.new(tool, :review, context: context)
        shell = Shell.new

        status = exit_status || (missing ? 127 : 0)
        mock_status = MockProcessStatus.new(exitstatus: status)
        mock_result = Shell::Result.new('stdout', 'stderr', mock_status)
        mock_timer = Shell::Timer.new(prep: 1.0, main: 2.5)

        shell.stub(:result, mock_result) do
          shell.stub(:timer, mock_timer) do
            runner = RunnerDouble.new(
              tool: tool, command: command, shell: shell,
              skipped: skipped, missing: missing, success: success
            )
            Result.from_runner(runner)
          end
        end
      end
    end
  end
end
