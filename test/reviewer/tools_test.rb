# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolsTest < Minitest::Test
    def setup
      @tools_hash = {
        enabled_tool: {
          name: "Enabled Tool",
          tags: ["disabled", "test", "fixture"],
          commands: {
            review: "bundle exec example review",
            format: "bundle exec example format",
          },
        },
        disabled_tool: {
          name: "Enabled Tool",
          tags: ["disabled", "test", "fixture"],
          commands: {
            review: "bundle exec example review",
            format: "bundle exec example format",
          },
        },
      }
      @tools = Tools.new(tools_hash: @tools_hash)
    end

    def test_exposes_all_configured_tools
      assert_equal @tools_hash.keys, @tools.all.map(&:key)
    end

    def test_exposes_all_enabled_tools
      @tools.enabled.each do |tool|
        assert tool.enabled?, "`#{tool.name}` is disabled but included in the enabled tools list"
      end
    end

    def test_exposes_all_disabled_tools
      @tools.disabled.each do |tool|
        assert tool.disabled?, "`#{tool.name}` is enabled but included in the disabled tools list"
      end
    end

    def test_includes_enabled_tagged_tools
      skip "Needs a test!"
    end

    def test_excludes_disabled_tagged_tools
      skip "Needs a test!"
    end
  end
end
