# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_review_command
      tools = [Tool.new(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_format_command
      tools = [Tool.new(:enabled_tool)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.format
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_returns_largest_exit_status_excluding_missing
      tools = [Tool.new(:list), Tool.new(:missing_command)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          # Missing tools (exit 127) should not affect exit status
          assert_equal 0, e.status
        end
      end
    end

    def test_clear_screen
      tools = [Tool.new(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review(clear_screen: true)
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_exits_with_guidance_when_config_missing
      original_file = Reviewer.configuration.file

      Reviewer.configuration.file = Pathname('test/fixtures/files/nonexistent.yml')

      # Non-TTY prompt returns false, so we get the skip message
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
    ensure
      Reviewer.configuration.file = original_file
    end

    def test_runs_setup_when_config_missing_and_user_says_yes
      original_file = Reviewer.configuration.file

      Reviewer.configuration.file = Pathname('test/fixtures/files/nonexistent.yml')

      tty_input = StringIO.new("y\n")
      tty_input.define_singleton_method(:tty?) { true }
      stub_prompt = Prompt.new(input: tty_input, output: StringIO.new)

      setup_ran = false
      Setup.stub(:run, -> { setup_ran = true }) do
        Reviewer.stub(:prompt, stub_prompt) do
          capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end
        end
      end

      assert setup_ran, 'Expected Setup.run to be called when user says yes'
    ensure
      Reviewer.configuration.file = original_file
    end

    def test_missing_tools_summary_shown_in_streaming_mode
      tools = [Tool.new(:list), Tool.new(:missing_with_install)]

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
      setup_ran = false
      Setup.stub(:run, -> { setup_ran = true }) do
        ARGV.replace(['init'])
        Reviewer.review
      ensure
        ARGV.replace([])
      end
      assert setup_ran, 'Expected Setup.run to be called for rvw init'
    end

    def test_review_dispatches_to_doctor_when_subcommand
      doctor_ran = false
      Doctor.stub(:run, lambda {
        doctor_ran = true
        Doctor::Report.new
      }) do
        ARGV.replace(['doctor'])
        capture_subprocess_io { Reviewer.review }
      ensure
        ARGV.replace([])
      end
      assert doctor_ran, 'Expected Doctor.run to be called for rvw doctor'
    end

    def test_format_dispatches_to_init_when_subcommand
      setup_ran = false
      Setup.stub(:run, -> { setup_ran = true }) do
        ARGV.replace(['init'])
        Reviewer.format
      ensure
        ARGV.replace([])
      end
      assert setup_ran, 'Expected Setup.run to be called for fmt init'
    end

    def test_format_dispatches_to_doctor_when_subcommand
      doctor_ran = false
      Doctor.stub(:run, lambda {
        doctor_ran = true
        Doctor::Report.new
      }) do
        ARGV.replace(['doctor'])
        capture_subprocess_io { Reviewer.format }
      ensure
        ARGV.replace([])
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

    def test_review_dispatches_to_capabilities_with_long_flag
      ARGV.replace(['--capabilities'])
      out, _err = capture_subprocess_io { Reviewer.review }
      assert_match(/"version"/, out)
      assert_match(/"tools"/, out)
    ensure
      ARGV.replace([])
    end

    def test_review_dispatches_to_capabilities_with_short_flag
      ARGV.replace(['-c'])
      out, _err = capture_subprocess_io { Reviewer.review }
      assert_match(/"version"/, out)
      assert_match(/"keywords"/, out)
    ensure
      ARGV.replace([])
    end
  end
end
