# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class DoctorOutputTest < Minitest::Test
    def test_renders_ok_report
      report = Reviewer::Doctor::Report.new
      report.add(:configuration, status: :ok, message: '.reviewer.yml found')
      report.add(:environment, status: :ok, message: 'Ruby 3.2.0')

      out = capture_output(report)
      assert_match(/Configuration/, out)
      assert_match(/\.reviewer\.yml found/, out)
      assert_match(/Environment/, out)
      assert_match(/No issues found/, out)
    end

    def test_renders_error_report
      report = Reviewer::Doctor::Report.new
      report.add(:configuration, status: :error, message: 'No .reviewer.yml found',
                                 detail: 'Run `rvw init` to generate one')

      out = capture_output(report)
      assert_match(/No \.reviewer\.yml found/, out)
      assert_match(/rvw init/, out)
      assert_match(/1 issue found/, out)
    end

    def test_renders_warning_findings
      report = Reviewer::Doctor::Report.new
      report.add(:environment, status: :warning, message: 'Not inside a git repository',
                               detail: 'Git keywords will not work')

      out = capture_output(report)
      assert_match(/Not inside a git repository/, out)
      assert_match(/Git keywords/, out)
      assert_match(/No issues found/, out) # warnings don't count as issues
    end

    def test_renders_multiple_errors
      report = Reviewer::Doctor::Report.new
      report.add(:configuration, status: :error, message: 'Error one')
      report.add(:configuration, status: :error, message: 'Error two')

      out = capture_output(report)
      assert_match(/2 issues found/, out)
    end

    def test_skips_empty_sections
      report = Reviewer::Doctor::Report.new
      report.add(:configuration, status: :ok, message: 'Config ok')
      # tools, opportunities, environment are empty

      out = capture_output(report)
      assert_match(/Configuration/, out)
      refute_match(/^Tools$/, out)
      refute_match(/^Opportunities$/, out)
      refute_match(/^Environment$/, out)
    end

    private

    def capture_output(report)
      output = Reviewer::Output.new
      out, _err = capture_subprocess_io { output.doctor_report(report) }
      out
    end
  end
end
