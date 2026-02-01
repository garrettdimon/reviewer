# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Reviewer
  module Doctor
    class ConfigCheckTest < Minitest::Test
      def test_reports_error_when_config_missing
        with_temp_config do
          report = Report.new
          ConfigCheck.new(report).check

          errors = report.section(:configuration).select { |f| f.status == :error }
          assert_equal 1, errors.size
          assert_match(/no .reviewer.yml found/i, errors.first.message)
          assert_match(/rvw init/, errors.first.detail)
        end
      end

      def test_reports_ok_when_config_valid
        ok_findings = run_check.select { |f| f.status == :ok }
        assert ok_findings.size >= 2
        assert(ok_findings.any? { |f| f.message =~ /found/i })
        assert(ok_findings.any? { |f| f.message =~ /valid/i })
      end

      def test_reports_error_for_invalid_yaml
        with_temp_config(content: 'bad: yaml: [invalid') do
          report = Report.new
          ConfigCheck.new(report).check

          errors = report.section(:configuration).select { |f| f.status == :error }
          assert(errors.any? { |f| f.message =~ /yaml syntax error/i })
        end
      end

      def test_reports_error_for_missing_review_command
        with_temp_config(content: "tool:\n  commands:\n    format: 'ls'") do
          report = Report.new
          ConfigCheck.new(report).check

          errors = report.section(:configuration).select { |f| f.status == :error }
          assert(errors.any? { |f| f.message =~ /missing review command/i })
        end
      end

      private

      def run_check
        report = Report.new
        ConfigCheck.new(report).check
        report.section(:configuration)
      end

      def with_temp_config(content: nil)
        original_file = Reviewer.configuration.file

        Dir.mktmpdir do |dir|
          config_file = Pathname(dir).join('.reviewer.yml')
          config_file.write(content) if content

          Reviewer.configuration.file = config_file
          yield config_file
        end
      ensure
        Reviewer.configuration.file = original_file
      end
    end
  end
end
