# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_review_command
      # The test tools don't exist, so a 127 exit code is expected
      missing_command_result = { enabled_tool: Shell::Result::EXIT_STATUS_CODES[:executable_not_found] }
      assert_equal missing_command_result, Reviewer.review
    end

    def test_format_command
      # The test tools don't exist, so a 127 exit code is expected
      missing_command_result = { enabled_tool: Shell::Result::EXIT_STATUS_CODES[:executable_not_found] }
      assert_equal missing_command_result, Reviewer.format
    end
  end
end
