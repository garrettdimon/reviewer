# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class DoctorOutputTest < Minitest::Test
    def test_renders_configured_tools_and_discoveries_separately
      report = example_report

      out = capture_output(report)

      assert_match(/Reviewer Doctor/, out)
      assert_match(/Configured tools/, out)
      assert_match(/Minitest \(tests\)/, out)
      assert_match(/Review\s+bundle exec rake test/, out)
      assert_match(/Configured in\s+\.reviewer\.yml › tests/, out)
      assert_match(/Discoveries/, out)
      assert_match(/ESLint/, out)
      assert_match(/Command\s+eslint \./, out)
      assert_match(/Discovered via\s+package\.json › scripts\.lint/, out)
      refute_match(/Opportunities|recommend|Add a `format`|Add a `files`/, out)
    end

    def test_collapses_successful_environment_facts
      out = capture_output(example_report)

      assert_match(/Ruby #{Regexp.escape(RUBY_VERSION)} · git 2\.40\.0 · repository/, out)
    end

    def test_renders_missing_configuration_without_calling_it_an_error
      report = Doctor::Report.new
      report.set_configuration(path: '.reviewer.yml', state: :missing)

      out = capture_output(report)

      assert_match(/\.reviewer\.yml not found/, out)
      assert_match(/No tools configured · 0 discovered/, out)
      refute_match(/issue found|rvw init/, out)
    end

    private

    def example_report
      report = Doctor::Report.new
      report.set_configuration(path: '.reviewer.yml', state: :valid)
      report.add_configured_tool(
        key: :tests,
        name: 'Minitest',
        skip_in_batch: false,
        commands: { review: 'bundle exec rake test' },
        files: { pattern: '*_test.rb' },
        source: { path: '.reviewer.yml', location: 'tests' }
      )
      report.add_discovery(
        key: :eslint,
        name: 'ESLint',
        observations: [Doctor::Report::Observation.new(
          kind: :command,
          value: 'eslint .',
          path: 'package.json',
          location: 'scripts.lint'
        )]
      )
      report.add_environment(name: :ruby, status: :ok, value: RUBY_VERSION)
      report.add_environment(name: :git, status: :ok, value: '2.40.0')
      report.add_environment(name: :repository, status: :ok, value: 'repository')
      report
    end

    def capture_output(report)
      output = Reviewer::Output.new
      out, _err = capture_subprocess_io { Doctor::Formatter.new(output).print(report) }
      out
    end
  end
end
