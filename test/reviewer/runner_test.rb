# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class RunnerTest < MiniTest::Test
    def setup
      allow_printing_output!
    end

    def teardown
      ensure_test_configuration!
    end

    def test_determines_success_based_on_configured_max_exit_status_for_review
      runner = Runner.new(:enabled_tool, :review)
      max_exit_status = 3
      assert_equal max_exit_status, runner.tool.max_exit_status
      runner.stub(:exit_status, max_exit_status) do
        assert runner.success?
      end
      runner.stub(:exit_status, max_exit_status + 1) do
        refute runner.success?
      end
    end

    def test_ignores_max_exit_status_for_non_review_commands
      runner = Runner.new(:enabled_tool, :format)
      runner.stub(:exit_status, 0) do
        assert runner.success?
      end
      runner.stub(:exit_status, 1) do
        refute runner.success?
      end
    end
  end
end
