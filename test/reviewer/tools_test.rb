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
      @tools = Tools.new(tools: @tools_hash)
    end

    def teardown
      ensure_test_configuration!
    end

    def test_exposes_all_configured_tools
      assert_equal @tools_hash, @tools.all
    end

    def test_exposes_all_enabled_tools
      @tools.enabled.each do |key, value|
        refute value[:disabled], "`#{key}` is disabled but included in the enabled tools list"
      end
    end

    def test_exposes_all_disabled_tools
      @tools.disabled.each do |key, value|
        assert value[:disabled], "`#{key}` is enabled but included in the disabled tools list"
      end
    end

    def test_exposes_tagged_tools
      @tools.enabled.each do |key, value|
        refute value[:disabled], "`#{key}` is disabled but included in the enabled tools list"
      end
      @tools.disabled.each do |key, value|
        assert value[:disabled], "`#{key}` is enabled but included in the disabled tools list"
      end
    end
  end
end
