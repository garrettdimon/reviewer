# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class KeywordCheckTest < Minitest::Test
      def test_no_warnings_for_clean_config
        report = run_check_with(configuration.file)
        warnings = report.section(:configuration).select { |finding| finding.status == :warning }
        assert_empty warnings
      end

      def test_warns_when_tool_name_shadows_reserved_keyword
        warning = assert_single_conflict_warning(/tool name.*staged.*reserved/i)
        assert_match(/rename/i, warning.detail)
      end

      def test_warns_when_tag_shadows_reserved_keyword
        warning = assert_single_conflict_warning(/tag.*failed.*reserved/i)
        assert_match(/-t/i, warning.detail)
      end

      def test_warns_when_tool_name_shadows_tag
        warning = assert_single_conflict_warning(/tool name.*ruby.*tag/i)
        assert_match(/-t/i, warning.detail)
      end

      def test_skips_when_config_missing
        Dir.mktmpdir do |dir|
          with_config_file(Pathname(dir).join('.reviewer.yml')) do
            report = Report.new
            KeywordCheck.new(report, configuration: configuration, tools: Reviewer.tools).check
            assert_empty report.section(:configuration)
          end
        end
      end

      private

      def configuration
        @configuration ||= Reviewer.configuration
      end

      def conflicts_fixture
        Pathname('test/fixtures/files/naming_conflicts.yml')
      end

      def with_config_file(config_file)
        original = configuration.file
        configuration.file = config_file
        yield
      ensure
        configuration.file = original
      end

      def run_check_with(config_file)
        tools = Tools.new(config_file: config_file)
        report = Report.new
        with_config_file(config_file) do
          KeywordCheck.new(report, configuration: configuration, tools: tools).check
        end
        report
      end

      def conflicts_report
        @conflicts_report ||= run_check_with(conflicts_fixture)
      end

      def assert_single_conflict_warning(pattern)
        matching = conflicts_report.section(:configuration).select { |finding| finding.status == :warning && finding.message.match?(pattern) }
        assert_equal 1, matching.size
        matching.first
      end
    end
  end
end
