# frozen_string_literal: true

require 'open3'

module Reviewer
  module Doctor
    # Checks environment prerequisites (git, Ruby version)
    class EnvironmentCheck
      attr_reader :report

      # Creates an environment checker for Ruby and git availability
      # @param report [Doctor::Report] the report to add findings to
      #
      # @return [EnvironmentCheck]
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
        report.add_environment(name: :ruby, status: :ok, value: RUBY_VERSION)
      end

      def check_git
        stdout, _stderr, status = Open3.capture3('git --version')

        unless status.success?
          report.add_environment(
            name: :git,
            status: :warning,
            value: 'not available',
            detail: 'Git keywords (staged, modified, etc.) require git'
          )
          return
        end

        report.add_environment(
          name: :git,
          status: :ok,
          value: stdout.strip.delete_prefix('git version ')
        )
        check_git_repo
      end

      def check_git_repo
        _stdout, _stderr, status = Open3.capture3('git rev-parse --git-dir')

        if status.success?
          report.add_environment(name: :repository, status: :ok, value: 'repository')
        else
          report.add_environment(
            name: :repository,
            status: :warning,
            value: 'not inside a git repository',
            detail: 'Git keywords (staged, modified, etc.) will not work'
          )
        end
      end
    end
  end
end
