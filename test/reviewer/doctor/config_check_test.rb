# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Reviewer
  module Doctor
    class ConfigCheckTest < Minitest::Test
      def test_reports_missing_configuration_as_state
        with_temp_config do
          report = Report.new
          state = ConfigCheck.new(report, configuration: Reviewer.configuration).check

          assert_equal :missing, state
          assert_equal :missing, report.configuration_state
          assert_empty report.errors
        end
      end

      def test_reports_valid_configuration_as_state
        report, state = run_check

        assert_equal :valid, state
        assert_equal :valid, report.configuration_state
        assert_empty report.section(:configuration)
      end

      def test_reports_error_for_invalid_yaml
        with_temp_config(content: 'bad: yaml: [invalid') do
          report = Report.new
          state = ConfigCheck.new(report, configuration: Reviewer.configuration).check

          assert_equal :invalid, state
          assert_equal :invalid, report.configuration_state
          errors = report.section(:configuration).select { |f| f.status == :error }
          assert(errors.any? { |f| f.message =~ /invalid configuration/i })
        end
      end

      def test_reports_error_for_missing_review_command
        with_temp_config(content: "tool:\n  commands:\n    format: 'ls'") do
          report = Report.new
          state = ConfigCheck.new(report, configuration: Reviewer.configuration).check

          assert_equal :invalid, state
          errors = report.section(:configuration).select { |f| f.status == :error }
          assert(errors.any? { |f| f.message =~ /missing review command/i })
        end
      end

      def test_reports_empty_yaml_as_invalid
        with_swapped_config(Pathname('test/fixtures/files/empty.yml')) do
          report = Report.new
          state = ConfigCheck.new(report, configuration: Reviewer.configuration).check

          assert_equal :invalid, state
          assert_equal :invalid, report.configuration_state
          assert_match(/invalid configuration/i, report.errors.first.message)
        end
      end

      def test_reports_non_mapping_commands_as_invalid
        with_swapped_config(Pathname('test/fixtures/files/test_commands_invalid_shape.yml')) do
          report = Report.new
          state = ConfigCheck.new(report, configuration: Reviewer.configuration).check

          assert_equal :invalid, state
          assert_equal :invalid, report.configuration_state
        end
      end

      private

      def run_check
        report = Report.new
        state = ConfigCheck.new(report, configuration: Reviewer.configuration).check
        [report, state]
      end

      def with_temp_config(content: nil)
        Dir.mktmpdir do |dir|
          config_file = Pathname(dir).join('.reviewer.yml')
          config_file.write(content) if content

          with_swapped_config(config_file) { yield config_file }
        end
      end
    end
  end
end
