# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class LoggerTest < MiniTest::Test
    def setup
      @tool = Tool.new(:enabled_tool)
      @logger = Logger.new
    end

    def test_prints_to_standard_out
      out, _err = capture_subprocess_io do
        @logger.info(@tool.description)
      end
      assert_match(/#{@tool.description}/i, out)
    end
  end
end
