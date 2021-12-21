# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Output
    class PrinterTest < MiniTest::Test
      def setup
        @printer = Printer.new
      end

      def test_builds_style_tokens
        token = Token.new(:success, 'success')
        assert_equal "\e[0;32msuccess\e[0m", token.to_s
      end

      def test_exposes_print
        out, _err = capture_subprocess_io { @printer.print(:default, 'print text') }
        assert_equal 'print text', out
      end

      def test_exposes_puts
        out, _err = capture_subprocess_io { @printer.puts(:default, 'puts text') }
        assert_equal "puts text\n", out
      end

      def test_prints_unstyled_text
        @printer.stub(:style_enabled?, false) do
          out, _err = capture_subprocess_io { @printer.print(:error, 'error') }
          assert_equal 'error', out
        end
      end

      def test_prints_styled_text_when_able
        @printer.stub(:style_enabled?, true) do
          out, _err = capture_subprocess_io { @printer.print(:error, 'colorized error') }
          assert_equal "\e[1;31mcolorized error\e[0m", out
        end
      end
    end
  end
end
