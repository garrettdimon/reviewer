# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ConversionsTest < MiniTest::Test
    include Conversions

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

    def test_verbosity_from_verbosity_instance
      verbosity = Command::Verbosity.new(Command::Verbosity::TOTAL_SILENCE)
      assert_equal verbosity, Verbosity(verbosity)
    end

    def test_verbosity_from_symbol
      verbosity = Command::Verbosity.new(Command::Verbosity::TOTAL_SILENCE)
      assert_equal verbosity, Verbosity(:total_silence)
    end

    def test_verbosity_from_string
      verbosity = Command::Verbosity.new(Command::Verbosity::TOTAL_SILENCE)
      assert_equal verbosity, Verbosity('total_silence')
    end

    def test_verbosity_from_integer
      verbosity = Command::Verbosity.new(Command::Verbosity::TOTAL_SILENCE)
      assert_equal verbosity, Verbosity(0)
    end

    def test_verbosity_from_unrecognized
      assert_raises TypeError do
        Verbosity(nil)
      end
    end
  end
end
