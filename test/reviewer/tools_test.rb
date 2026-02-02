# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolsTest < Minitest::Test
    def test_exposes_all_configured_tools
      @tools = Tools.new(config_file: config_file)

      assert_equal Reviewer.tools.all.map(&:key), @tools.all.map(&:key)
    end

    def test_exposes_all_enabled_tools
      @tools = Tools.new(config_file: config_file)
      @tools.enabled.each do |tool|
        assert tool.enabled?, "`#{tool.name}` is disabled but included in the enabled tools list"
      end
    end

    def test_includes_enabled_tools_if_non_specified
      @tools = Tools.new(config_file: config_file)
      assert_equal 2, @tools.current.size
      refute_includes @tools.current, build_tool(:disabled_tool)
    end

    def test_includes_enabled_tagged_tools
      @tools = Tools.new(tags: %w[ruby css], tool_names: [], config_file: config_file)
      assert_equal 1, @tools.current.size
      assert_equal 'Enabled Test Tool', @tools.current.first.name
    end

    def test_includes_tagged_tools_via_keyword
      arguments = Arguments.new(%w[ruby])
      @tools = Tools.new(arguments: arguments, config_file: config_file)
      assert_equal 1, @tools.current.size
      assert_equal 'Enabled Test Tool', @tools.current.first.name
    end

    def test_excludes_disabled_tagged_tools
      @tools = Tools.new(tags: %w[html], tool_names: [], config_file: config_file)
      assert @tools.current.empty?
    end

    def test_includes_enabled_named_tools
      @tools = Tools.new(tags: [], tool_names: %w[enabled_tool], config_file: config_file)
      assert_equal 1, @tools.current.size
      assert_equal 'Enabled Test Tool', @tools.current.first.name
    end

    def test_includes_disabled_named_tools
      @tools = Tools.new(tags: [], tool_names: %w[disabled_tool], config_file: config_file)
      assert_equal 1, @tools.current.size
      assert_equal 'Disabled Test Tool', @tools.current.first.name
    end

    def test_excludes_skip_in_batch_tools_from_enabled
      @tools = Tools.new(config_file: config_file)
      @tools.enabled.each do |tool|
        refute tool.skip_in_batch?, "`#{tool.name}` is skip_in_batch but included in enabled tools"
      end
    end

    def test_removes_duplicate_tools
      @tools = Tools.new(tags: %w[tagged], tool_names: %w[tagged], config_file: config_file)
      assert_equal 1, @tools.current.size
      assert_equal 'Tagged', @tools.current.first.name
    end

    def test_failed_from_history_returns_tools_with_failed_status
      history = Reviewer.history
      clear_all_last_statuses(history)
      history.set(:enabled_tool, :last_status, :failed)
      history.set(:tagged, :last_status, :passed)

      @tools = Tools.new(history: history, config_file: config_file)
      failed = @tools.failed_from_history
      assert_equal 1, failed.size
      assert_equal :enabled_tool, failed.first.key
    ensure
      history.set(:enabled_tool, :last_status, nil)
      history.set(:tagged, :last_status, nil)
    end

    def test_failed_from_history_returns_empty_when_no_failures
      history = Reviewer.history
      clear_all_last_statuses(history)
      history.set(:enabled_tool, :last_status, :passed)

      @tools = Tools.new(history: history, config_file: config_file)
      assert_empty @tools.failed_from_history
    ensure
      history.set(:enabled_tool, :last_status, nil)
    end

    def test_current_includes_failed_tools
      history = Reviewer.history
      history.set(:list, :last_status, :failed)
      arguments = Arguments.new(%w[failed])

      @tools = Tools.new(arguments: arguments, history: history, config_file: config_file)
      tool_keys = @tools.current.map(&:key)
      assert_includes tool_keys, :list
    ensure
      history.set(:list, :last_status, nil)
    end

    def test_current_unions_failed_tools_with_named_tools
      history = Reviewer.history
      history.set(:list, :last_status, :failed)
      arguments = Arguments.new(%w[failed enabled_tool])

      @tools = Tools.new(arguments: arguments, history: history, config_file: config_file)
      tool_keys = @tools.current.map(&:key)
      assert_includes tool_keys, :list
      assert_includes tool_keys, :enabled_tool
    ensure
      history.set(:list, :last_status, nil)
    end

    private

    def config_file = Reviewer.configuration.file

    def clear_all_last_statuses(history)
      Reviewer.tools.all.each { |tool| history.set(tool.key, :last_status, nil) }
    end
  end
end
