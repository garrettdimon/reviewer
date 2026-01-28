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

      def test_result_is_immutable
        assert_raises(FrozenError) do
          @result.instance_variable_set(:@tool_key, :other)
        end
      end
    end
  end
end
