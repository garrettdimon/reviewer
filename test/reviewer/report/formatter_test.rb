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

      def test_all_missing_report_does_not_say_all_passed
        @report.add(build_missing_result(tool_key: :rubocop, tool_name: 'RuboCop'))
        @report.record_duration(0.5)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        refute_match(/all passed/i, out)
        assert_match(/1 missing/i, out)
      end

      def test_aligns_tool_names_and_durations_across_varied_lengths
        @report.add(build_result(tool_key: :bundle_audit, tool_name: 'Bundle Audit', success: true, duration: 0.16))
        @report.add(build_result(tool_key: :tests, tool_name: 'Minitest', success: true, duration: 5.07))
        @report.add(build_result(tool_key: :flog, tool_name: 'Flog', success: true, duration: 0.22))
        @report.record_duration(5.45)

        formatter = Formatter.new(@report)
        out, _err = capture_subprocess_io { formatter.print }

        positions = duration_column_positions(out, 'Bundle Audit', 'Minitest', 'Flog')
        assert_equal 1, positions.uniq.size, "Duration columns misaligned: #{positions}"
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

      def test_failure_details_exclude_skipped_tools
        @report.add(build_result(
                      tool_key: :tests,
                      success: false,
                      exit_status: 1,
                      stdout: 'test failure output'
                    ))
        @report.add(build_skipped_result(tool_key: :rubocop))

        out, _err = capture_subprocess_io { Formatter.new(@report).print }

        assert_match(/Tests:/i, out)
        refute_match(/Rubocop:/i, out)
      end

      def test_skipped_tool_is_not_rendered_as_a_pass
        @report.add(build_result(tool_key: :tests, success: true))
        @report.add(build_skipped_result(tool_key: :rubocop))
        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        rubocop_line = out.lines.find { |line| line.include?('Rubocop') }
        refute_includes rubocop_line, Output::Formatting::CHECKMARK
        assert_match(/no matching files/i, rubocop_line)
      end

      def test_skipped_tool_shows_no_timing
        @report.add(build_skipped_result(tool_key: :rubocop))
        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        rubocop_line = out.lines.find { |line| line.include?('Rubocop') }
        refute_match(/\d+\.\d+s/, rubocop_line)
      end

      def test_summary_counts_skipped_separately_from_passed
        2.times { |i| @report.add(build_result(tool_key: :"ran#{i}", success: true)) }
        3.times { |i| @report.add(build_skipped_result(tool_key: :"skip#{i}")) }
        @report.record_duration(1.5)
        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        refute_match(/all passed/i, out)
        assert_match(/2 passed/i, out)
        assert_match(/3 skipped/i, out)
      end

      def test_summary_counts_missing_separately
        @report.add(build_result(tool_key: :tests, success: true))
        @report.add(build_skipped_result(tool_key: :rubocop))
        @report.add(build_missing_result(tool_key: :reek))
        @report.record_duration(1.5)

        out, _err = capture_subprocess_io { Formatter.new(@report).print }

        assert_match(/1 passed/i, out)
        assert_match(/1 skipped/i, out)
        assert_match(/1 missing/i, out)
      end

      def test_formats_not_run_tool_without_timing_or_failure_details
        @report.add(build_result(
                      tool_key: :tests,
                      success: false,
                      exit_status: 1,
                      stdout: 'test failure output'
                    ))
        @report.add(Runner::Result.not_run(tool: build_tool(:enabled_tool), command_type: :review))

        out, _err = capture_subprocess_io { Formatter.new(@report).print }
        line = out.lines.find { |candidate| candidate.include?('Enabled Test Tool') }

        assert_match(/^- .*Enabled Test Tool/, line)
        assert_match(/stopped after failure/i, line)
        refute_match(/\d+\.\d+s/, line)
        assert_match(/1 not_run/i, out)
        refute_match(/Enabled Test Tool:/i, out)
      end

      def test_formats_one_result_in_every_state
        @report.add(build_result(tool_key: :passed, success: true))
        @report.add(build_result(tool_key: :failed, success: false, exit_status: 1, stdout: 'failure'))
        @report.add(build_skipped_result(tool_key: :skipped))
        @report.add(build_missing_result(tool_key: :missing))
        @report.add(Runner::Result.not_run(tool: build_tool(:enabled_tool), command_type: :review))

        out, _err = capture_subprocess_io { Formatter.new(@report).print }

        expected = <<~OUTPUT
          ✓ Passed                 1.0s
          ✗ Failed                 1.0s
          - Skipped              no matching files
          - Missing              not installed
          - Enabled Test Tool    stopped after failure


          Failed:
          failure
          1 passed, 1 failed, 1 skipped, 1 missing, 1 not_run (0.0s)
        OUTPUT
        assert_equal expected, out
      end

      def test_all_passed_still_shown_when_nothing_skipped
        @report.add(build_result(tool_key: :tests, success: true))
        @report.record_duration(1.5)
        formatter = Formatter.new(@report)

        out, _err = capture_subprocess_io { formatter.print }

        assert_match(/all passed/i, out)
      end

      private

      def duration_column_positions(output, *tool_names)
        lines = output.lines.map(&:chomp)
        tool_names.map { |name| lines.find { |l| l.include?(name) }.index(/\d+\.\d+s/) }
      end

      def build_skipped_result(tool_key:, tool_name: nil)
        Runner::Result.new(
          tool_key: tool_key,
          tool_name: tool_name || tool_key.to_s.capitalize,
          command_type: :review,
          command_string: nil,
          success: true,
          exit_status: 0,
          duration: 0,
          stdout: nil,
          stderr: nil,
          skipped: true,
          missing: nil
        )
      end

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
