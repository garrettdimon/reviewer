# frozen_string_literal: true

require 'open3'

module Reviewer
  module Doctor
    # Checks environment prerequisites (git, Ruby version)
    class EnvironmentCheck
      attr_reader :report

      # @param report [Doctor::Report] the report to add findings to
      def initialize(report)
        @report = report
      end

      # Checks Ruby version and git availability
      def check
        check_ruby_version
        check_git
      end

      private

      def check_ruby_version
        report.add(:environment, status: :ok, message: "Ruby #{RUBY_VERSION}")
      end

      def check_git
        stdout, _stderr, status = Open3.capture3('git --version')

        unless status.success?
          report.add(:environment, status: :warning,
                                   message: 'Git not available',
                                   detail: 'Git keywords (staged, modified, etc.) require git')
          return
        end

        report.add(:environment, status: :ok, message: stdout.strip)
        check_git_repo
      end

      def check_git_repo
        _stdout, _stderr, status = Open3.capture3('git rev-parse --git-dir')

        if status.success?
          report.add(:environment, status: :ok, message: 'Inside a git repository')
        else
          report.add(:environment, status: :warning,
                                   message: 'Not inside a git repository',
                                   detail: 'Git keywords (staged, modified, etc.) will not work')
        end
      end
    end
  end
end
