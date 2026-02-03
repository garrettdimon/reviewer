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

      Doctor::Report::SECTIONS.each do |section|
        refute_empty report.section(section),
                     "Expected #{section} section to have findings"
      end
    end

    def test_report_is_ok_with_valid_config
      report = Doctor.run(configuration: Reviewer.configuration, tools: Reviewer.tools)
      assert report.ok?
    end

    def test_report_has_error_when_config_missing
      with_missing_config do
        report = Doctor.run(configuration: Reviewer.configuration, tools: Reviewer.tools)
        refute report.ok?
        assert(report.errors.any? { |f| f.message =~ /no .reviewer.yml/i })
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
