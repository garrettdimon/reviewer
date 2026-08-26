# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class ToolInventoryTest < Minitest::Test
      def test_reports_all_configured_tools
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        refute_empty report.configured_tools
      end

      def test_enabled_tool_reported_as_ok
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        enabled = report.configured_tools.find { |tool| tool.name == 'Enabled Test Tool' }
        refute enabled.skip_in_batch
      end

      def test_disabled_tool_reported_as_muted
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        disabled = report.configured_tools.find { |tool| tool.name == 'Disabled Test Tool' }
        assert disabled.skip_in_batch
      end

      def test_includes_command_name_in_message
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        tool = report.configured_tools.find { |configured| configured.name == 'Enabled Test Tool' }
        assert_equal :enabled_tool, tool.key
      end

      def test_includes_command_summary_in_message
        report = Report.new
        ToolInventory.new(report, configuration: Reviewer.configuration, tools: Reviewer.tools).check

        tool = report.configured_tools.find { |configured| configured.name == 'Enabled Test Tool' }
        assert_equal 'ls -c', tool.commands[:review]
        assert_equal({ path: Reviewer.configuration.file.to_s, location: 'enabled_tool' }, tool.source)
      end
    end
  end
end
