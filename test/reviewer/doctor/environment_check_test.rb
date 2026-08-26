# frozen_string_literal: true

require 'test_helper'
require 'open3'

module Reviewer
  module Doctor
    class EnvironmentCheckTest < Minitest::Test
      def test_reports_ruby_version
        report = Report.new
        EnvironmentCheck.new(report).check

        ruby_finding = report.environment.find { |finding| finding.name == :ruby }
        assert ruby_finding
        assert_equal :ok, ruby_finding.status
        assert_equal RUBY_VERSION, ruby_finding.value
      end

      def test_reports_git_version_when_available
        report = Report.new
        EnvironmentCheck.new(report).check

        git_finding = report.environment.find { |finding| finding.name == :git }
        assert git_finding
        assert_equal :ok, git_finding.status
        assert_match(/\d+\.\d+/, git_finding.value)
      end

      def test_reports_warning_when_git_unavailable
        report = run_with_failed_git

        ruby = find_env(report, :ruby)
        assert ruby

        git = find_env(report, :git)
        assert git
        assert_equal :warning, git.status
      end

      def test_reports_git_repo_status
        report = Report.new
        EnvironmentCheck.new(report).check

        repo_finding = report.environment.find { |finding| finding.name == :repository }
        assert repo_finding
        assert_equal 'repository', repo_finding.value
      end

      def test_reports_warning_when_not_in_git_repo
        report = run_with_git_but_no_repo

        not_repo = find_env(report, :repository)
        assert not_repo
        assert_equal :warning, not_repo.status
      end

      private

      def find_env(report, name)
        report.environment.find { |finding| finding.name == name }
      end

      def run_with_git_but_no_repo
        report = Report.new
        check = EnvironmentCheck.new(report)
        git_ok = MockProcessStatus.new(exitstatus: 0, pid: 1)
        repo_fail = MockProcessStatus.new(exitstatus: 128, pid: 2)

        Open3.stub(:capture3, lambda { |cmd|
          cmd.include?('--version') ? ['git version 2.40.0', '', git_ok] : ['', 'fatal', repo_fail]
        }) { check.check }

        report
      end

      def run_with_failed_git
        report = Report.new
        check = EnvironmentCheck.new(report)

        failed_status = MockProcessStatus.new(exitstatus: 1, pid: 1)
        Open3.stub(:capture3, ['', 'not found', failed_status]) do
          check.check
        end

        report
      end
    end
  end
end
