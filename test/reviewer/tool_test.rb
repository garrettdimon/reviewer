# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ToolTest < MiniTest::Test
    def setup
      @tool = Tool.new(:enabled_tool)
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

    def test_installation_command
      cmd = @tool.installation_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec gem install example", cmd
    end

    def test_preparation_command
      cmd = @tool.preparation_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example update --quiet > /dev/null", cmd
    end

    def test_review_command
      cmd = @tool.review_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example review --third 'third flag' --fourth 'fourth flag' --quiet > /dev/null", cmd
    end

    def test_format_command
      cmd = @tool.format_command
      assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example format", cmd
    end

    def test_command_with_seed
      tool = Tool.new(:dynamic_seed_tool)
      seed = 123
      cmd = tool.review_command(seed: seed)
      assert_equal "bundle exec example review --seed #{seed} > /dev/null", cmd
    end

    def test_can_track_last_prepared_at_across_runs
      timestamp = Time.current

      tool_one = Tool.new(:enabled_tool)
      tool_two = Tool.new(:enabled_tool)
      tool_one.last_prepared_at = timestamp

      assert_equal timestamp, tool_one.last_prepared_at
      assert_equal tool_one.last_prepared_at, tool_two.last_prepared_at
    end
  end
end
