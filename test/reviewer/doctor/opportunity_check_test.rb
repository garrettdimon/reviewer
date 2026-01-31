# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class OpportunityCheckTest < Minitest::Test
      FIXTURES = Pathname('test/fixtures/projects')

      def test_detects_unconfigured_tools
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('ruby_project')).check

        # Test config doesn't include rubocop, reek, etc. but ruby_project has them
        messages = report.section(:opportunities).map(&:message)
        assert(messages.any? { |m| m.include?('detected but not configured') })
      end

      def test_flags_tools_without_files_config
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

        # enabled_tool and tagged tools in test config lack files config
        messages = report.section(:opportunities).map(&:message)
        assert(messages.any? { |m| m.include?('no file targeting') })
      end

      def test_flags_tools_without_format_command
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

        messages = report.section(:opportunities).map(&:message)
        assert(messages.any? { |m| m.include?('no format command') })
      end

      def test_skips_when_config_missing
        Dir.mktmpdir do |dir|
          config_file = Pathname(dir).join('.reviewer.yml')
          Reviewer.configure { |c| c.file = config_file }

          report = Report.new
          OpportunityCheck.new(report, FIXTURES.join('ruby_project')).check

          assert_empty report.section(:opportunities)
        end
      ensure
        ensure_test_configuration!
      end
    end
  end
end
