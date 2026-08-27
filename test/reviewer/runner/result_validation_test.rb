# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    class ResultValidationTest < Minitest::Test
      def test_rejects_unknown_state
        error = assert_raises(ArgumentError) do
          Result.new(
            tool_key: :tests, tool_name: 'Tests', command_type: :review,
            command_string: nil, state: :timed_out, exit_status: nil,
            duration: nil, stdout: nil, stderr: nil
          )
        end

        assert_equal 'Unknown result state: :timed_out', error.message
      end

      def test_rejects_absent_state
        error = assert_raises(ArgumentError) do
          Result.new(
            tool_key: :tests, tool_name: 'Tests', command_type: :review,
            command_string: nil, exit_status: nil, duration: nil,
            stdout: nil, stderr: nil
          )
        end

        assert_equal 'Unknown result state: nil', error.message
      end
    end
  end
end
