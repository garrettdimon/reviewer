# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    def setup
      # Don't dump output when running tests
      # 4 = fatal which isn't used anywhere
      Reviewer.logger.level = 4

      # The test tools don't exist, so a 127 exit code is expected
      @missing_command_result = { enabled_tool: Runner::Result::EXIT_STATUS_CODES[:executable_not_found] }
    end

    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_review_command
      # skip "Needs logging suppression, but logger isn't explicitly passed any longer"
      assert_equal @missing_command_result, Reviewer.review
    end

    def test_format_command
      # skip "Needs logging suppression, but logger isn't explicitly passed any longer"
      assert_equal @missing_command_result, Reviewer.review
    end
  end
end
