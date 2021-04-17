# frozen_string_literal: true

require "test_helper"

module Reviewer
  class ToolsTest < MiniTest::Test
    def setup
    end

    def test_it_exposes_an_array_of_all_configured_tools
      assert Tools.all.is_a? Array
    end

    def test_it_exposes_an_array_of_all_enabled_tools
      assert Tools.enabled.is_a? Array
    end

    def test_it_exposes_an_array_of_all_disabled_tools
      assert Tools.disabled.is_a? Array
    end
  end
end
