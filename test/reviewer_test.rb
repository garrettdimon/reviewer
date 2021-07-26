# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    def setup
      # The test tools don't exist, so a 127 exit code is expected
      @missing_command_result = { enabled_tool: Runner::Result::EXIT_STATUS_CODES[:executable_not_found] }
    end

    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_review_command
      @missing_command_result = { enabled_tool: Runner::Result::EXIT_STATUS_CODES[:executable_not_found] }
      assert_equal @missing_command_result, Reviewer.review
    end

    def test_format_command
      # For formatting, it either worked or it didn't. So it's not caught up in more specific exit
      # statuses like the review command is.
      @missing_command_result = { enabled_tool: 1, list: 0 }
      capture_subprocess_io do
        assert_equal @missing_command_result, Reviewer.format
      end
    end
  end
end
