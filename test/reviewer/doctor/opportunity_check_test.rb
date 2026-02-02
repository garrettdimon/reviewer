# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class OpportunityCheckTest < Minitest::Test
      FIXTURES = Pathname('test/fixtures/projects')

      def test_detects_unconfigured_tools
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('ruby_project'),
                             configuration: Reviewer.configuration,
                             tools: Reviewer.tools).check

        # Test config doesn't include rubocop, reek, etc. but ruby_project has them
        messages = report.section(:opportunities).map(&:message)
        assert(messages.any? { |m| m.include?('detected but not configured') })
      end

      def test_skips_file_targeting_for_tools_not_in_catalog
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('empty_project'),
                             configuration: Reviewer.configuration,
                             tools: Reviewer.tools).check

        # enabled_tool and tagged are not in the catalog, so no file targeting suggestions
        messages = report.section(:opportunities).map(&:message)
        refute(messages.any? { |m| m.include?('no file targeting') })
      end

      def test_skips_format_for_tools_not_in_catalog
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('empty_project'),
                             configuration: Reviewer.configuration,
                             tools: Reviewer.tools).check

        # enabled_tool and tagged are not in the catalog, so no format suggestions
        messages = report.section(:opportunities).map(&:message)
        refute(messages.any? { |m| m.include?('no format command') })
      end

      def test_suggests_files_for_catalog_tool_that_supports_them
        # Stub a tool that matches a catalog entry with :files (e.g., reek)
        tool = build_tool(:enabled_tool)
        tool.settings.stub(:key, :reek) do
          tool.stub(:disabled?, false) do
            tool.stub(:supports_files?, false) do
              tools = stub_tools(all: [tool])
              report = Report.new
              OpportunityCheck.new(report, FIXTURES.join('empty_project'),
                                   configuration: Reviewer.configuration,
                                   tools: tools).check

              messages = report.section(:opportunities).map(&:message)
              assert(messages.any? { |m| m.include?('no file targeting') })
            end
          end
        end
      end

      def test_skips_files_for_catalog_tool_without_files
        # bundle_audit is in the catalog but has no :files key
        tool = build_tool(:enabled_tool)
        tool.settings.stub(:key, :bundle_audit) do
          tool.stub(:disabled?, false) do
            tool.stub(:supports_files?, false) do
              tools = stub_tools(all: [tool])
              report = Report.new
              OpportunityCheck.new(report, FIXTURES.join('empty_project'),
                                   configuration: Reviewer.configuration,
                                   tools: tools).check

              messages = report.section(:opportunities).map(&:message)
              refute(messages.any? { |m| m.include?('no file targeting') })
            end
          end
        end
      end

      def test_suggests_format_for_catalog_tool_that_supports_it
        # rubocop is in the catalog with a :format command
        tool = build_tool(:enabled_tool)
        tool.settings.stub(:key, :rubocop) do
          tool.stub(:disabled?, false) do
            tool.stub(:formattable?, false) do
              tools = stub_tools(all: [tool])
              report = Report.new
              OpportunityCheck.new(report, FIXTURES.join('empty_project'),
                                   configuration: Reviewer.configuration,
                                   tools: tools).check

              messages = report.section(:opportunities).map(&:message)
              assert(messages.any? { |m| m.include?('no format command') })
            end
          end
        end
      end

      def test_skips_format_for_catalog_tool_without_format
        # tests (minitest) is in the catalog but has no :format command
        tool = build_tool(:enabled_tool)
        tool.settings.stub(:key, :tests) do
          tool.stub(:disabled?, false) do
            tool.stub(:formattable?, false) do
              tools = stub_tools(all: [tool])
              report = Report.new
              OpportunityCheck.new(report, FIXTURES.join('empty_project'),
                                   configuration: Reviewer.configuration,
                                   tools: tools).check

              messages = report.section(:opportunities).map(&:message)
              refute(messages.any? { |m| m.include?('no format command') })
            end
          end
        end
      end

      def test_catalog_supports_returns_false_for_unknown_capability
        check = OpportunityCheck.new(Report.new, FIXTURES.join('empty_project'),
                                     configuration: Reviewer.configuration,
                                     tools: Reviewer.tools)
        # :rubocop is in the catalog, but :unknown is not a recognized capability
        refute check.send(:catalog_supports?, :rubocop, :unknown)
      end

      def test_skips_when_config_missing
        report = run_with_missing_config
        assert_empty report.section(:opportunities)
      end

      private

      def run_with_missing_config
        original_file = Reviewer.configuration.file
        Dir.mktmpdir do |dir|
          Reviewer.configuration.file = Pathname(dir).join('.reviewer.yml')
          report = Report.new
          OpportunityCheck.new(report, FIXTURES.join('ruby_project'),
                               configuration: Reviewer.configuration,
                               tools: Reviewer.tools).check
          report
        end
      ensure
        Reviewer.configuration.file = original_file
      end

      def stub_tools(all:)
        tools = Minitest::Mock.new
        tools.expect(:all, all)
        tools.expect(:all, all)
        tools.expect(:all, all)
        tools
      end
    end
  end
end
