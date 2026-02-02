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
                      stdout: '0.19s · 209 tests (1102.02/s) with 419 assertions',
                      summary_pattern: '(\d+)\s+tests?',
                      summary_label: '\1 tests'
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
                      stdout: '70 files inspected, 3 offenses detected',
                      summary_pattern: '(\d+)\s+offenses?',
                      summary_label: '\1 offenses'
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

      def test_formats_missing_tool_with_dash_and_not_installed
        @report.add(build_result(tool_key: :bundle_audit, tool_name: 'Bundle Audit', success: true, duration: 0.15))
        @report.add(build_missing_result(tool_key: :rubocop, tool_name: 'RuboCop'))
        @report.add(build_result(tool_key: :tests, tool_name: 'Minitest', success: true, duration: 0.46))
        @report.record_duration(0.61)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/- RuboCop/i, out)
        assert_match(/not installed/i, out)
      end

      def test_missing_tool_excluded_from_failure_details
        @report.add(build_missing_result(tool_key: :rubocop, tool_name: 'RuboCop'))
        @report.record_duration(0.5)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        # Should show "All passed" since the only non-missing tools all passed
        assert_match(/all passed/i, out)
      end

      def test_mixed_missing_and_failed_shows_only_real_failures
        @report.add(build_result(
                      tool_key: :tests,
                      tool_name: 'Minitest',
                      success: false,
                      exit_status: 1,
                      stdout: 'test failure output'
                    ))
        @report.add(build_missing_result(tool_key: :rubocop, tool_name: 'RuboCop'))
        @report.record_duration(0.8)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        # Should show failure details for Minitest but not RuboCop
        assert_match(/Minitest:/i, out)
        refute_match(/RuboCop:/i, out)
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
          skipped: nil,
          missing: nil,
          summary_pattern: options[:summary_pattern],
          summary_label: options[:summary_label]
        )
      end

      def build_missing_result(tool_key:, tool_name: nil)
        Runner::Result.new(
          tool_key: tool_key,
          tool_name: tool_name || tool_key.to_s.capitalize,
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
      end
    end
  end
end
