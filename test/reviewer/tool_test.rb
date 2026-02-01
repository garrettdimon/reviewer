# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolTest < Minitest::Test
    def setup
      @tool = Tool.new(:enabled_tool)
      @mvt = Tool.new(:minimum_viable_tool)
    end

    def test_name_and_casting_to_string
      assert_equal 'Enabled Test Tool', @tool.to_s
      assert_equal @tool.to_s, @tool.name
    end

    def test_compares_settings_values_for_equality
      tool_one = Tool.new(:enabled_tool)
      tool_two = Tool.new(:enabled_tool)
      tool_three = Tool.new(:disabled_tool)
      assert tool_one == tool_two
      assert tool_one.eql?(tool_two)
      refute tool_one == tool_three
      refute tool_one.eql?(tool_three)
    end

    def test_knows_when_a_tool_needs_to_run_its_preparation_step
      @tool.last_prepared_at = nil
      assert @tool.stale?

      @tool.last_prepared_at = Time.now - (Tool::SIX_HOURS_IN_SECONDS + 1)
      assert @tool.stale?

      @tool.last_prepared_at = Time.now - (Tool::SIX_HOURS_IN_SECONDS - 1)
      refute @tool.stale?
    end

    def test_never_considers_a_tool_stale_if_it_does_not_have_a_prepare_command
      @mvt = Tool.new(:minimum_viable_tool)
      refute @mvt.preparable?

      # The last prepared at date is definitely stale...
      @mvt.last_prepared_at = Time.now - (Tool::SIX_HOURS_IN_SECONDS * 2)
      refute @mvt.stale?
    end

    def test_can_track_last_prepared_at_across_runs
      timestamp = Time.now

      tool_one = Tool.new(:enabled_tool)
      tool_two = Tool.new(:enabled_tool)
      tool_one.last_prepared_at = timestamp

      assert_equal timestamp.to_s, tool_one.last_prepared_at.to_s
      assert_equal tool_one.last_prepared_at, tool_two.last_prepared_at
    end

    def test_knows_if_a_command_has_an_install_link_configured
      assert @tool.install_link?
      refute @mvt.install_link?
    end

    def test_returns_the_install_link
      assert_nil @mvt.install_link
      assert_equal 'https://example.com/install', @tool.install_link
    end

    def test_delegates_skip_in_batch
      tool = Tool.new(:disabled_tool)
      assert tool.skip_in_batch?

      tool = Tool.new(:enabled_tool)
      refute tool.skip_in_batch?
    end

    def test_knows_if_a_command_is_installable
      assert @tool.installable?
      refute @mvt.installable?
    end

    def test_knows_if_a_command_is_preparable
      assert @tool.preparable?
      refute @mvt.preparable?
    end

    def test_knows_if_a_command_is_reviewable
      assert @tool.reviewable?
      assert @mvt.reviewable?
    end

    def test_knows_if_a_command_is_formattable
      assert @tool.formattable?
      refute @mvt.formattable?
    end

    def test_resolve_files_delegates_to_file_resolver
      tool = Tool.new(:file_pattern_tool)

      result = tool.resolve_files(['app/models/user.rb', 'app.js'])

      assert_equal ['app/models/user.rb'], result
    end

    def test_resolve_files_returns_files_unchanged_when_no_pattern
      result = @tool.resolve_files(['app/models/user.rb', 'app.js'])

      assert_equal ['app/models/user.rb', 'app.js'], result
    end

    def test_skip_files_returns_true_when_files_requested_but_none_match
      tool = Tool.new(:file_pattern_tool)

      assert tool.skip_files?(['app.js', 'style.css'])
    end

    def test_skip_files_returns_false_when_no_files_requested
      tool = Tool.new(:file_pattern_tool)

      refute tool.skip_files?([])
    end
  end
end
