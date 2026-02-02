# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Reviewer
  class DoctorTest < Minitest::Test
    def test_run_returns_report
      report = Doctor.run
      assert_kind_of Doctor::Report, report
    end

    def test_report_has_all_sections
      report = Doctor.run

      Doctor::Report::SECTIONS.each do |section|
        refute_empty report.section(section),
                     "Expected #{section} section to have findings"
      end
    end

    def test_report_is_ok_with_valid_config
      report = Doctor.run
      assert report.ok?
    end

    def test_report_has_error_when_config_missing
      with_missing_config do
        report = Doctor.run
        refute report.ok?
        assert(report.errors.any? { |f| f.message =~ /no .reviewer.yml/i })
      end
    end

    private

    def with_missing_config
      original_file = Reviewer.configuration.file
      Dir.mktmpdir do |dir|
        Reviewer.configuration.file = Pathname(dir).join('.reviewer.yml')
        yield
      end
    ensure
      Reviewer.configuration.file = original_file
    end
  end
end
