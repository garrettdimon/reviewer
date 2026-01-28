# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Report
    class FormatterTest < Minitest::Test
      def setup
        @report = Report.new
      end

      def test_formats_empty_report_with_no_tools_message
        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/no tools/i, out)
      end

      def test_formats_successful_report_with_checkmarks_and_summary
        @report.add(build_result(tool_key: :bundle_audit, tool_name: 'Bundle Audit', success: true, duration: 0.15))
        @report.add(build_result(tool_key: :tests, tool_name: 'Minitest', success: true, duration: 0.46))
        @report.record_duration(0.61)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/✓.*Bundle Audit/i, out)
        assert_match(/✓.*Minitest/i, out)
        assert_match(/0\.15s/, out)
        assert_match(/all passed/i, out)
      end

      def test_formats_failure_with_x_mark_and_details
        @report.add(build_result(
                      tool_key: :rubocop,
                      tool_name: 'RuboCop',
                      success: false,
                      exit_status: 1,
                      stdout: "lib/foo.rb:10:5: Style/StringLiterals\nlib/bar.rb:20:3: Layout/LineLength"
                    ))
        @report.record_duration(0.8)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/✗.*RuboCop/i, out)
        refute_match(/all passed/i, out)
        assert_match(%r{lib/foo\.rb}, out)
      end

      def test_extracts_test_count_from_minitest_output
        @report.add(build_result(
                      tool_key: :tests,
                      tool_name: 'Minitest',
                      success: true,
                      stdout: '0.19s · 209 tests (1102.02/s) with 419 assertions'
                    ))
        @report.record_duration(0.5)

        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/209 tests/i, out)
      end

      def test_extracts_offense_count_from_rubocop_output
        @report.add(build_result(
                      tool_key: :rubocop,
                      tool_name: 'RuboCop',
                      success: false,
                      exit_status: 1,
                      stdout: '70 files inspected, 3 offenses detected'
                    ))
        @report.record_duration(0.8)

        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/3 offenses/i, out)
      end

      def test_truncates_long_failure_output
        long_output = (1..20).map { |i| "Line #{i}: Some error message" }.join("\n")

        @report.add(build_result(
                      tool_key: :rubocop,
                      tool_name: 'RuboCop',
                      success: false,
                      exit_status: 1,
                      stdout: long_output
                    ))
        @report.record_duration(0.8)

        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        # Should show first 10 lines
        assert_match(/Line 1:/, out)
        assert_match(/Line 10:/, out)

        # Should not show lines beyond 10
        refute_match(/Line 11:/, out)
        refute_match(/Line 20:/, out)

        # Should show truncation notice
        assert_match(/10 more lines/, out)
      end

      private

      def build_result(tool_key:, success:, **options)
        Runner::Result.new(
          tool_key: tool_key,
          tool_name: options[:tool_name] || tool_key.to_s.capitalize,
          command_type: :review,
          command_string: "bundle exec #{tool_key}",
          success: success,
          exit_status: options[:exit_status] || 0,
          duration: options[:duration] || 1.0,
          stdout: options[:stdout],
          stderr: options[:stderr],
          skipped: nil
        )
      end
    end
  end
end
