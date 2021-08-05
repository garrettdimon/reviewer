# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class PrinterTest < MiniTest::Test
    def setup
      @tool = Tool.new(:enabled_tool)
      @printer = Printer.new
    end

    def test_prints_to_standard_out
      out, _err = capture_subprocess_io do
        @printer.info(@tool.description)
      end
      assert_match(/#{@tool.description}/i, out)
    end
  end
end
