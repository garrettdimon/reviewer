# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolsTest < MiniTest::Test
    def test_it_exposes_an_array_of_all_configured_tools
      assert Tools.all.is_a? Array
    end

    def test_it_creates_tool_instances_in_the_array
      assert Tools.all.first.is_a? Tool
    end
  end
end
