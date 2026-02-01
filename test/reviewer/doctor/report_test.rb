# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class ReportTest < Minitest::Test
      def test_new_report_is_ok
        report = Report.new
        assert report.ok?
      end

      def test_add_finding_to_section
        report = Report.new
        report.add(:configuration, status: :ok, message: 'Config found')

        assert_equal 1, report.section(:configuration).size
        assert_equal :ok, report.section(:configuration).first.status
      end

      def test_add_finding_with_detail
        report = Report.new
        report.add(:configuration, status: :error, message: 'Missing', detail: 'Run rvw init')

        finding = report.section(:configuration).first
        assert_equal 'Run rvw init', finding.detail
      end

      def test_ok_is_false_with_errors
        report = Report.new
        report.add(:configuration, status: :error, message: 'Bad config')

        refute report.ok?
      end

      def test_ok_is_true_with_warnings_only
        report = Report.new
        report.add(:environment, status: :warning, message: 'No git')

        assert report.ok?
      end

      def test_errors_returns_only_errors
        report = Report.new
        report.add(:configuration, status: :ok, message: 'Good')
        report.add(:configuration, status: :error, message: 'Bad')
        report.add(:environment, status: :error, message: 'Also bad')

        assert_equal 2, report.errors.size
        assert(report.errors.all? { |f| f.status == :error })
      end

      def test_warnings_returns_only_warnings
        report = Report.new
        report.add(:environment, status: :warning, message: 'Heads up')
        report.add(:environment, status: :ok, message: 'Fine')

        assert_equal 1, report.warnings.size
        assert_equal :warning, report.warnings.first.status
      end

      def test_section_returns_empty_for_unused_section
        report = Report.new

        assert_empty report.section(:tools)
      end

      def test_sections_constant
        assert_includes Report::SECTIONS, :configuration
        assert_includes Report::SECTIONS, :tools
        assert_includes Report::SECTIONS, :opportunities
        assert_includes Report::SECTIONS, :environment
      end
    end
  end
end
