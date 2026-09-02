# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    def setup
      ARGV.clear
      Reviewer.instance_variable_set(:@arguments, nil)
    end

    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_review_command
      tools = [build_tool(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_format_command
      tools = [build_tool(:enabled_tool)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.format
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_returns_largest_exit_status_excluding_missing
      tools = [build_tool(:list), build_tool(:missing_command)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          # Missing tools (exit 127) should not affect exit status
          assert_equal 0, e.status
        end
      end
    end

    def test_review_runs_successfully
      tools = [build_tool(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_exits_with_guidance_when_config_missing
      with_missing_config do
        stub_prompt = Prompt.new(input: StringIO.new, output: StringIO.new)
        Reviewer.stub(:prompt, stub_prompt) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit => e
            assert_equal 0, e.status
          end

          assert_match(/setting up Reviewer/i, out)
          assert_match(/rvw init/, out)
        end
      end
    end

    def test_missing_files_option_precedes_first_time_setup
      with_missing_config do
        out, _err = with_argv('-f') do
          capture_subprocess_io do
            error = assert_raises(SystemExit) { Reviewer.review }
            assert_equal Session::USAGE_ERROR, error.status
          end
        end

        assert_match(/requires at least one file or path/, out)
        refute_match(/setting up Reviewer/i, out)
      end
    end

    def test_json_missing_files_option_precedes_first_time_setup
      with_missing_config do
        out, _err = with_argv('-f', '--json') do
          capture_subprocess_io do
            error = assert_raises(SystemExit) { Reviewer.review }
            assert_equal Session::USAGE_ERROR, error.status
          end
        end
        payload = JSON.parse(out)

        assert_equal missing_files_payload, payload
      end
    end

    def test_runs_setup_when_config_missing_and_user_says_yes
      with_missing_config do
        stub_prompt = build_tty_prompt("y\n")
        setup_ran = false
        Setup.stub(:run, ->(configuration:, **) { setup_ran = !configuration.nil? }) do
          Reviewer.stub(:prompt, stub_prompt) do
            capture_subprocess_io do
              Reviewer.review
            rescue SystemExit
              # Expected
            end
          end
        end

        assert setup_ran, 'Expected Setup.run to be called when user says yes'
      end
    end

    def test_missing_tools_summary_shown_in_streaming_mode
      tools = [build_tool(:list), build_tool(:missing_with_install)]

      Reviewer.tools.stub(:current, tools) do
        out, _err = capture_subprocess_io do
          Reviewer.review
        rescue SystemExit
          # Expected
        end

        assert_match(/not installed:/i, out)
        assert_match(/Missing With Install/i, out)
        assert_match(/gem install missing-tool/, out)
      end
    end

    def test_review_dispatches_to_init_when_subcommand
      received = nil
      Setup.stub(:run, ->(configuration:, **) { received = configuration }) do
        with_argv('init') { Reviewer.review }
      end
      assert received, 'Expected Setup.run to receive a configuration for rvw init'
    end

    def test_review_dispatches_to_doctor_when_subcommand
      doctor_ran = false
      Doctor.stub(:run, lambda { |**|
        doctor_ran = true
        Doctor::Report.new
      }) do
        with_argv('doctor') { capture_subprocess_io { Reviewer.review } }
      end
      assert doctor_ran, 'Expected Doctor.run to be called for rvw doctor'
    end

    def test_doctor_json_serializes_the_report_without_terminal_formatting
      report = Doctor::Report.new
      report.set_configuration(path: '.reviewer.yml', state: :missing)

      Doctor.stub(:run, report) do
        out, _err = with_argv('doctor', '--json') { capture_subprocess_io { Reviewer.review } }
        parsed = JSON.parse(out)

        assert_equal 1, parsed.fetch('schema_version')
        assert_equal 'missing', parsed.dig('configuration', 'state')
        refute_match(/\e\[/, out)
      end
    end

    def test_format_dispatches_to_init_when_subcommand
      received = nil
      Setup.stub(:run, ->(configuration:, **) { received = configuration }) do
        with_argv('init') { Reviewer.format }
      end
      assert received, 'Expected Setup.run to receive a configuration for fmt init'
    end

    def test_format_dispatches_to_doctor_when_subcommand
      doctor_ran = false
      Doctor.stub(:run, lambda { |**|
        doctor_ran = true
        Doctor::Report.new
      }) do
        with_argv('doctor') { capture_subprocess_io { Reviewer.format } }
      end
      assert doctor_ran, 'Expected Doctor.run to be called for fmt doctor'
    end

    def test_configure_yields_configuration
      config = Configuration.new
      yielded = nil
      Reviewer.stub(:configuration, config) do
        Reviewer.configure { |c| yielded = c }
      end
      assert_same config, yielded
    end

    def test_review_prints_help_and_exits_early
      with_argv('--help') do
        out, _err = capture_subprocess_io { Reviewer.review }
        assert_match(/--help/, out)
        assert_match(/--version/, out)
        assert_match(/rvw init.*deprecated/i, out)
        assert_match(/rvw doctor.*configuration and project discoveries/i, out)
      end
    end

    def test_review_help_describes_failed_as_the_last_executed_review
      out, _err = with_argv('--help') { capture_subprocess_io { Reviewer.review } }

      assert_equal 2, out.scan(/last executed review failed/i).size
      refute_match(/failed last time/i, out)
    end

    def test_review_prints_version_and_exits_early
      with_argv('--version') do
        out, _err = capture_subprocess_io { Reviewer.review }
        assert_match(/#{Reviewer::VERSION}/, out)
      end
    end

    def test_format_prints_help_and_exits_early
      with_argv('--help') do
        out, _err = capture_subprocess_io { Reviewer.format }
        assert_match(/--help/, out)
        assert_match(/--version/, out)
      end
    end

    def test_format_prints_version_and_exits_early
      with_argv('--version') do
        out, _err = capture_subprocess_io { Reviewer.format }
        assert_match(/#{Reviewer::VERSION}/, out)
      end
    end

    def test_review_dispatches_to_capabilities_with_long_flag
      out = nil
      with_argv('--capabilities') { out, = capture_subprocess_io { Reviewer.review } }
      assert_match(/"version"/, out)
      assert_match(/"tools"/, out)
    end

    def test_review_dispatches_to_capabilities_with_short_flag
      out = nil
      with_argv('-c') { out, = capture_subprocess_io { Reviewer.review } }
      assert_match(/"version"/, out)
      assert_match(/"keywords"/, out)
    end

    private

    def with_argv(*args)
      ARGV.replace(args)
      Reviewer.instance_variable_set(:@arguments, nil)
      yield
    ensure
      ARGV.replace([])
      Reviewer.instance_variable_set(:@arguments, nil)
    end

    def with_missing_config
      with_swapped_config(Pathname('test/fixtures/files/nonexistent.yml')) { yield }
    end

    def build_tty_prompt(input_text)
      tty_input = StringIO.new(input_text)
      tty_input.define_singleton_method(:tty?) { true }
      Prompt.new(input: tty_input, output: StringIO.new)
    end

    def missing_files_payload
      {
        'schema_version' => 1,
        'state' => 'error',
        'error' => {
          'code' => 'missing_files',
          'message' => 'The --files option requires at least one file or path.'
        },
        'summary' => Report.empty_summary.transform_keys(&:to_s),
        'tools' => []
      }
    end
  end
end
