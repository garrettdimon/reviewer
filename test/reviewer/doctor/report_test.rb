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
        assert_includes Report::SECTIONS, :configured_tools
        assert_includes Report::SECTIONS, :discoveries
        assert_includes Report::SECTIONS, :environment
      end

      def test_serializes_configuration_and_summary
        report = Report.new
        report.set_configuration(path: '.reviewer.yml', state: :valid)

        serialized = report.to_h
        assert_equal 1, serialized[:schema_version]
        assert_equal({ path: '.reviewer.yml', state: :valid, findings: [] }, serialized[:configuration])
        assert_equal 0, serialized[:summary][:configured_tools]
        assert_equal 0, serialized[:summary][:discoveries]
      end

      def test_serializes_configured_tools
        report = Report.new
        report.add_configured_tool(
          key: :tests,
          name: 'Minitest',
          skip_in_batch: false,
          commands: { review: 'bundle exec rake test' },
          files: { pattern: '*_test.rb' },
          source: { path: '.reviewer.yml', location: 'tests' }
        )

        tool = report.to_h[:configured_tools].first
        assert_equal :tests, tool[:key]
        assert_equal 'bundle exec rake test', tool[:commands][:review]
        assert_equal({ pattern: '*_test.rb' }, tool[:files])
      end

      def test_serializes_discoveries
        report = Report.new
        report.add_discovery(
          key: :eslint,
          name: 'ESLint',
          observations: [Report::Observation.new(
            kind: :command,
            value: 'eslint .',
            path: 'package.json',
            location: 'scripts.lint'
          )]
        )

        discovery = report.to_h[:discoveries].first
        assert_equal :eslint, discovery[:key]
        assert_equal 'eslint .', discovery[:observations].first[:value]
      end

      def test_serializes_environment
        report = Report.new
        report.add_environment(name: :ruby, status: :ok, value: RUBY_VERSION)

        assert_equal RUBY_VERSION, report.to_h[:environment].first[:value]
      end
    end
  end
end
