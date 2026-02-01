# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ConversionsTest < Minitest::Test
    include Tool::Conversions

    def test_tool_from_tool_instance
      tool = Tool.new(:enabled_tool)
      assert_equal tool, Tool(tool)
    end

    def test_tool_from_symbol
      tool = Tool.new(:enabled_tool)
      assert_equal tool, Tool(:enabled_tool)
    end

    def test_tool_from_string
      tool = Tool.new(:enabled_tool)
      assert_equal tool, Tool('enabled_tool')
    end

    def test_tool_from_unrecognized
      assert_raises TypeError do
        Tool(1)
      end
    end
  end
end
