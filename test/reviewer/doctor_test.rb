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
      Dir.mktmpdir do |dir|
        config_file = Pathname(dir).join('.reviewer.yml')
        Reviewer.configure { |c| c.file = config_file }

        report = Doctor.run
        refute report.ok?
        assert(report.errors.any? { |f| f.message =~ /no .reviewer.yml/i })
      end
    ensure
      ensure_test_configuration!
    end
  end
end
