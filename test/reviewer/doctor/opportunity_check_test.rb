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

      def test_skips_file_targeting_for_tools_not_in_catalog
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

        # enabled_tool and tagged are not in the catalog, so no file targeting suggestions
        messages = report.section(:opportunities).map(&:message)
        refute(messages.any? { |m| m.include?('no file targeting') })
      end

      def test_skips_format_for_tools_not_in_catalog
        report = Report.new
        OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

        # enabled_tool and tagged are not in the catalog, so no format suggestions
        messages = report.section(:opportunities).map(&:message)
        refute(messages.any? { |m| m.include?('no format command') })
      end

      def test_suggests_files_for_catalog_tool_that_supports_them
        # Stub a tool that matches a catalog entry with :files (e.g., reek)
        tool = Tool.new(:enabled_tool)
        tool.settings.stub(:key, :reek) do
          tool.stub(:disabled?, false) do
            tool.stub(:supports_files?, false) do
              Reviewer.tools.stub(:all, [tool]) do
                report = Report.new
                OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

                messages = report.section(:opportunities).map(&:message)
                assert(messages.any? { |m| m.include?('no file targeting') })
              end
            end
          end
        end
      end

      def test_skips_files_for_catalog_tool_without_files
        # bundle_audit is in the catalog but has no :files key
        tool = Tool.new(:enabled_tool)
        tool.settings.stub(:key, :bundle_audit) do
          tool.stub(:disabled?, false) do
            tool.stub(:supports_files?, false) do
              Reviewer.tools.stub(:all, [tool]) do
                report = Report.new
                OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

                messages = report.section(:opportunities).map(&:message)
                refute(messages.any? { |m| m.include?('no file targeting') })
              end
            end
          end
        end
      end

      def test_suggests_format_for_catalog_tool_that_supports_it
        # rubocop is in the catalog with a :format command
        tool = Tool.new(:enabled_tool)
        tool.settings.stub(:key, :rubocop) do
          tool.stub(:disabled?, false) do
            tool.stub(:formattable?, false) do
              Reviewer.tools.stub(:all, [tool]) do
                report = Report.new
                OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

                messages = report.section(:opportunities).map(&:message)
                assert(messages.any? { |m| m.include?('no format command') })
              end
            end
          end
        end
      end

      def test_skips_format_for_catalog_tool_without_format
        # tests (minitest) is in the catalog but has no :format command
        tool = Tool.new(:enabled_tool)
        tool.settings.stub(:key, :tests) do
          tool.stub(:disabled?, false) do
            tool.stub(:formattable?, false) do
              Reviewer.tools.stub(:all, [tool]) do
                report = Report.new
                OpportunityCheck.new(report, FIXTURES.join('empty_project')).check

                messages = report.section(:opportunities).map(&:message)
                refute(messages.any? { |m| m.include?('no format command') })
              end
            end
          end
        end
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
