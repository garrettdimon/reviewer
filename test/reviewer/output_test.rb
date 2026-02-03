# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class OutputTest < Minitest::Test
    def setup
      @output = Output.new
    end

    # === Primitives ===

    def test_newline
      out, _err = capture_subprocess_io { @output.newline }
      assert_match(/\n/i, out)
    end

    def test_divider
      out, _err = capture_subprocess_io { @output.divider }
      assert_match(/#{Output::DIVIDER}/i, out)
    end

    def test_unfiltered
      content = 'Content'
      out, _err = capture_subprocess_io { @output.unfiltered(content) }
      assert_match(/#{content}/i, out)
    end

    def test_unfiltered_skips_printing_if_nothing_to_show
      content = nil
      out, _err = capture_subprocess_io { @output.unfiltered(content) }
      assert_empty out

      content = ''
      out, _err = capture_subprocess_io { @output.unfiltered(content) }
      assert_empty out
    end

    def test_clear_skips_when_not_tty
      stream = StringIO.new
      printer = Output::Printer.new(stream)
      output = Output.new(printer)
      output.clear
      assert_empty stream.string
    end

    def test_help_prints_message
      out, _err = capture_subprocess_io { @output.help('Usage: rvw') }
      assert_match(/Usage: rvw/, out)
    end

    def test_console_width_returns_default_when_io_console_nil
      IO.stub(:console, nil) do
        output = Output.new
        assert_equal Output::DEFAULT_CONSOLE_WIDTH, output.send(:console_width)
      end
    end

    def test_console_width_returns_default_when_winsize_zero
      fake_console = Object.new
      fake_console.define_singleton_method(:winsize) { [0, 0] }
      IO.stub(:console, fake_console) do
        output = Output.new
        assert_equal Output::DEFAULT_CONSOLE_WIDTH, output.send(:console_width)
      end
    end

    def test_console_width_returns_actual_width_when_positive
      fake_console = Object.new
      fake_console.define_singleton_method(:winsize) { [24, 120] }
      IO.stub(:console, fake_console) do
        output = Output.new
        assert_equal 120, output.send(:console_width)
      end
    end

    def test_scrub_removes_rake_aborted_text
      text = "some error\nrake aborted!\nmore text"
      assert_equal "some error\n", Output.scrub(text)
    end

    def test_scrub_returns_empty_for_nil
      assert_equal '', Output.scrub(nil)
    end

    def test_scrub_returns_original_when_no_rake_text
      assert_equal 'clean output', Output.scrub('clean output')
    end
  end
end
