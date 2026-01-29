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

    def test_includes_enabled_tools_if_non_specified
      @tools = Tools.new
      assert_equal 2, @tools.current.size
      refute_includes @tools.current, Tool.new(:disabled_tool)
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

    def test_removes_duplicate_tools
      @tools = Tools.new(tags: %w[tagged], tool_names: %w[tagged])
      assert_equal 1, @tools.current.size
      assert_equal 'Tagged', @tools.current.first.name
    end

    def test_failed_from_history_returns_tools_with_failed_status
      clear_all_last_statuses
      Reviewer.history.set(:enabled_tool, :last_status, :failed)
      Reviewer.history.set(:tagged, :last_status, :passed)

      @tools = Tools.new
      failed = @tools.failed_from_history
      assert_equal 1, failed.size
      assert_equal :enabled_tool, failed.first.key
    ensure
      Reviewer.history.set(:enabled_tool, :last_status, nil)
      Reviewer.history.set(:tagged, :last_status, nil)
    end

    def test_failed_from_history_returns_empty_when_no_failures
      clear_all_last_statuses
      Reviewer.history.set(:enabled_tool, :last_status, :passed)

      @tools = Tools.new
      assert_empty @tools.failed_from_history
    ensure
      Reviewer.history.set(:enabled_tool, :last_status, nil)
    end

    def test_current_includes_failed_tools
      Reviewer.history.set(:list, :last_status, :failed)
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[failed]))

      @tools = Tools.new
      tool_keys = @tools.current.map(&:key)
      assert_includes tool_keys, :list
    ensure
      Reviewer.history.set(:list, :last_status, nil)
      Reviewer.reset!
      ensure_test_configuration!
    end

    def test_current_unions_failed_tools_with_named_tools
      Reviewer.history.set(:list, :last_status, :failed)
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[failed enabled_tool]))

      @tools = Tools.new
      tool_keys = @tools.current.map(&:key)
      assert_includes tool_keys, :list
      assert_includes tool_keys, :enabled_tool
    ensure
      Reviewer.history.set(:list, :last_status, nil)
      Reviewer.reset!
      ensure_test_configuration!
    end

    private

    def clear_all_last_statuses
      Reviewer.tools.all.each { |tool| Reviewer.history.set(tool.key, :last_status, nil) }
    end
  end
end
