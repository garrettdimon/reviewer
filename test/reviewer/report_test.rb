# frozen_string_literal: true

require 'test_helper'
require 'json'

module Reviewer
  class ReportTest < Minitest::Test
    def setup
      @report = Report.new
    end

    def test_starts_empty
      assert_empty @report.results
      assert_nil @report.duration
    end

    def test_add_appends_result
      result = build_result(tool_key: :rubocop, success: true)
      @report.add(result)

      assert_equal 1, @report.results.size
      assert_equal result, @report.results.first
    end

    def test_record_duration_sets_duration
      @report.record_duration(12.5)

      assert_equal 12.5, @report.duration
    end

    def test_success_when_all_results_succeed
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_result(tool_key: :tests, success: true))

      assert @report.success?
    end

    def test_not_success_when_any_result_fails
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_result(tool_key: :tests, success: false, exit_status: 1))

      refute @report.success?
    end

    def test_success_when_empty
      assert @report.success?
    end

    def test_max_exit_status_returns_highest
      @report.add(build_result(tool_key: :rubocop, success: true, exit_status: 0))
      @report.add(build_result(tool_key: :tests, success: false, exit_status: 2))
      @report.add(build_result(tool_key: :reek, success: false, exit_status: 1))

      assert_equal 2, @report.max_exit_status
    end

    def test_max_exit_status_returns_zero_when_empty
      assert_equal 0, @report.max_exit_status
    end

    def test_to_h_includes_success_status
      @report.add(build_result(tool_key: :rubocop, success: false, exit_status: 1))
      refute @report.to_h[:success]
    end

    def test_to_h_includes_summary_counts
      @report.add(build_result(tool_key: :rubocop, success: true, exit_status: 0))
      @report.add(build_result(tool_key: :tests, success: false, exit_status: 1))

      summary = @report.to_h[:summary]
      assert_equal 2, summary[:total]
      assert_equal 1, summary[:passed]
      assert_equal 1, summary[:failed]
    end

    def test_to_h_includes_duration
      @report.record_duration(8.5)
      assert_equal 8.5, @report.to_h[:summary][:duration]
    end

    def test_to_h_includes_tools_array
      @report.add(build_result(tool_key: :rubocop, success: true))
      assert_equal 1, @report.to_h[:tools].size
    end

    def test_to_json_returns_parseable_json
      @report.add(build_result(tool_key: :rubocop, success: true))
      parsed = JSON.parse(@report.to_json)
      assert parsed['success']
    end

    def test_to_json_includes_expected_structure
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.record_duration(5.0)
      parsed = JSON.parse(@report.to_json)

      assert_equal 1, parsed['summary']['total']
      assert_equal 'rubocop', parsed['tools'].first['tool']
    end

    def test_missing_results_returns_missing
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_missing_result(tool_key: :reek))

      assert_equal 1, @report.missing_results.size
      assert_equal :reek, @report.missing_results.first.tool_key
    end

    def test_missing_returns_true_when_missing_results_exist
      @report.add(build_missing_result(tool_key: :reek))

      assert @report.missing?
    end

    def test_missing_returns_false_when_no_missing_results
      @report.add(build_result(tool_key: :rubocop, success: true))

      refute @report.missing?
    end

    def test_success_excludes_missing_tools
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_missing_result(tool_key: :reek))

      assert @report.success?
    end

    def test_max_exit_status_excludes_missing_tools
      @report.add(build_result(tool_key: :rubocop, success: true, exit_status: 0))
      @report.add(build_missing_result(tool_key: :reek))

      assert_equal 0, @report.max_exit_status
    end

    def test_max_exit_status_returns_zero_when_only_missing
      @report.add(build_missing_result(tool_key: :reek))

      assert_equal 0, @report.max_exit_status
    end

    def test_to_h_summary_includes_missing_count
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_missing_result(tool_key: :reek))

      summary = @report.to_h[:summary]
      assert_equal 1, summary[:missing]
    end

    def test_to_h_failed_count_excludes_missing
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_missing_result(tool_key: :reek))

      summary = @report.to_h[:summary]
      assert_equal 0, summary[:failed]
    end

    def test_missing_tools_returns_missing_results
      @report.add(build_result(tool_key: :rubocop, success: true))
      @report.add(build_missing_result(tool_key: :list))

      missing = @report.missing_tools
      assert_equal 1, missing.size
      assert_instance_of Runner::Result, missing.first
      assert_equal :list, missing.first.tool_key
    end

    def test_missing_tools_returns_empty_when_none_missing
      @report.add(build_result(tool_key: :rubocop, success: true))

      assert_empty @report.missing_tools
    end

    private

    def build_result(tool_key:, success:, exit_status: 0)
      Runner::Result.new(
        tool_key: tool_key,
        tool_name: tool_key.to_s.capitalize,
        command_type: :review,
        command_string: "bundle exec #{tool_key}",
        success: success,
        exit_status: exit_status,
        duration: 1.0,
        stdout: nil,
        stderr: nil,
        skipped: nil,
        missing: nil
      )
    end

    def build_missing_result(tool_key:)
      Runner::Result.new(
        tool_key: tool_key,
        tool_name: tool_key.to_s.capitalize,
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
