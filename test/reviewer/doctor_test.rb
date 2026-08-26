# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Reviewer
  class DoctorTest < Minitest::Test
    def test_run_returns_report
      report = Doctor.run(configuration: Reviewer.configuration, tools: Reviewer.tools)
      assert_kind_of Doctor::Report, report
    end

    def test_report_has_all_sections
      report = Doctor.run(configuration: Reviewer.configuration, tools: Reviewer.tools)

      assert_equal :valid, report.configuration_state
      refute_empty report.configured_tools
      refute_empty report.discoveries
      refute_empty report.environment
    end

    def test_report_is_ok_with_valid_config
      report = Doctor.run(configuration: Reviewer.configuration, tools: Reviewer.tools)
      assert report.ok?
    end

    def test_report_still_discovers_tools_when_config_missing
      with_missing_config do
        report = Doctor.run(
          configuration: Reviewer.configuration,
          tools: Reviewer.tools,
          project_dir: Pathname('test/fixtures/projects/ruby_project')
        )

        assert_equal :missing, report.configuration_state
        assert_empty report.configured_tools
        assert_includes report.discoveries.map(&:key), :rubocop
        assert report.ok?
      end
    end

    def test_report_does_not_include_catalog_opportunities
      Doctor.run(configuration: Reviewer.configuration, tools: Reviewer.tools)

      refute_includes Doctor::Report::SECTIONS, :opportunities
    end

    def test_report_still_discovers_tools_when_config_is_invalid
      Dir.mktmpdir do |dir|
        config_file = Pathname(dir).join('.reviewer.yml')
        config_file.write('bad: yaml: [invalid')

        with_swapped_config(config_file) do
          report = Doctor.run(
            configuration: Reviewer.configuration,
            tools: Reviewer.tools,
            project_dir: Pathname('test/fixtures/projects/ruby_project')
          )

          assert_equal :invalid, report.configuration_state
          assert_empty report.configured_tools
          assert_includes report.discoveries.map(&:key), :rubocop
        end
      end
    end

    private

    def with_missing_config
      Dir.mktmpdir do |dir|
        with_swapped_config(Pathname(dir).join('.reviewer.yml')) { yield }
      end
    end
  end
end
