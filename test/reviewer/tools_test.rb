# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolsTest < Minitest::Test
    def test_exposes_all_configured_tools
      @tools = Tools.new
      assert_equal Reviewer.tools.all.map(&:key), @tools.all.map(&:key)
    end

    def test_exposes_all_enabled_tools
      @tools = Tools.new
      @tools.enabled.each do |tool|
        assert tool.enabled?, "`#{tool.name}` is disabled but included in the enabled tools list"
      end
    end

    def test_includes_enabled_tagged_tools
      @tools = Tools.new(tags: %w[ruby css], tool_names: [])
      assert_equal 1, @tools.current.size
      assert_equal 'Enabled Test Tool', @tools.current.first.name
    end

    def test_excludes_disabled_tagged_tools
      @tools = Tools.new(tags: %w[html], tool_names: [])
      assert @tools.current.empty?
    end

    def test_includes_enabled_named_tools
      @tools = Tools.new(tags: [], tool_names: %w[enabled_tool])
      assert_equal 1, @tools.current.size
      assert_equal 'Enabled Test Tool', @tools.current.first.name
    end

    def test_includes_disabled_named_tools
      @tools = Tools.new(tags: [], tool_names: %w[disabled_tool])
      assert_equal 1, @tools.current.size
      assert_equal 'Disabled Test Tool', @tools.current.first.name
    end
  end
end
