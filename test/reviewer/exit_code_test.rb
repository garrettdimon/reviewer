# frozen_string_literal: true

require 'test_helper'

module Reviewer
  # The process exit code answers one question: did this run pass? It is derived
  # from the report's verdict rather than from whatever a tool happened to return,
  # so a caller can tell "your code is bad" from "you used me wrong".
  class ExitCodeTest < Minitest::Test
    def build_result(exit_status:, success:, missing: nil, skipped: nil)
      Runner::Result.new(
        tool_key: :example, tool_name: 'Example', command_type: :review,
        command_string: 'example', success: success, exit_status: exit_status,
        duration: 0.1, stdout: '', stderr: '', missing: missing, skipped: skipped
      )
    end

    def report_with(*results)
      report = Report.new
      results.each { |result| report.add(result) }
      report
    end

    # A tool configured with max_exit_status passes on a non-zero status. The
    # process was still exiting with that raw status -- green payload, red shell.
    def test_a_tool_passing_under_max_exit_status_exits_zero
      report = report_with(build_result(exit_status: 1, success: true))

      assert_predicate report, :success?
      assert_equal 0, report.exit_code
    end

    # Tool exit codes are not a vocabulary Reviewer forwards: 2 is reserved for
    # usage errors, so any tool failure has to collapse to 1.
    def test_a_failing_tool_exits_one_whatever_it_returned
      report = report_with(build_result(exit_status: 2, success: false))

      assert_equal 1, report.exit_code
    end

    def test_all_passing_exits_zero
      report = report_with(build_result(exit_status: 0, success: true))

      assert_equal 0, report.exit_code
    end

    def test_a_run_with_nothing_executed_exits_zero
      report = report_with(build_result(exit_status: 127, success: false, missing: true))

      assert_equal 0, report.exit_code
    end
  end
end
