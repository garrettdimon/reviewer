# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class ToolInventoryTest < Minitest::Test
      def test_reports_all_configured_tools
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        tool_findings = report.section(:tools)
        refute_empty tool_findings
      end

      def test_enabled_tool_reported_as_ok
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        enabled = report.section(:tools).find { |f| f.message.include?('Enabled Test Tool') }
        assert enabled
        assert_equal :ok, enabled.status
        assert_match(/runs in batch/, enabled.message)
      end

      def test_disabled_tool_reported_as_muted
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        disabled = report.section(:tools).find { |f| f.message.include?('Disabled Test Tool') }
        assert disabled
        assert_equal :muted, disabled.status
        assert_match(/skip in batch/, disabled.message)
      end

      def test_includes_command_summary
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        finding = report.section(:tools).find { |f| f.message.include?('Enabled Test Tool') }
        assert_match(/Commands:/, finding.detail)
        assert_match(/review/, finding.detail)
      end
    end
  end
end
