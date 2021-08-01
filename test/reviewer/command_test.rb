# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class CommandTest < MiniTest::Test
    def setup
      @command = Reviewer::Command.new(:enabled_tool, :review, :no_silence)
    end

    def test_maintains_seed_despite_changes
      skip 'command seed tests'
    end

    def test_command_with_seed
      skip 'command seed tests'
      @command = Reviewer::Command.new(:enabled_tool, :review, :no_silence)
      tool = Tool.new(:dynamic_seed_tool)
      seed = 123
      cmd = tool.review_command(seed: seed)
      assert_equal "bundle exec example review --seed #{seed} > /dev/null", cmd
    end

    def test_records_last_used_seed_value_to_history
      skip 'Pending Removal or Move'
      tool = Tool.new(:dynamic_seed_tool)
      seed = 123
      tool.review_command(seed: seed)
      assert_equal Reviewer.history.get(tool.key, :last_seed), seed
    end

    def test_can_be_cast_to_string
      command_string = "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true bundle exec example review --third 'third flag' --fourth 'fourth flag'"

      assert_equal command_string, @command.string
      assert_equal @command.string, @command.to_s
    end

    def test_defaults_verbosity_to_total_silence
      command = Command.new(:enabled_tool, :review)
      verbosity = Command::Verbosity.new(Command::Verbosity::TOTAL_SILENCE)
      assert_equal verbosity, command.verbosity
    end

    def test_generates_fresh_string_after_verbosity_change
      skip "Pending Command Verbosity Change Test"
    end

    def test_raises_error_on_invalid_command_type
      assert_raises Reviewer::Command::InvalidTypeError do
        Command.new(:enabled_tool, :missing_command_type)
      end
    end

    def test_raises_error_if_command_type_is_not_defined_for_tool
      assert_raises Reviewer::Command::NotConfiguredError do
        Command.new(:minimum_viable_tool, :install)
      end
    end
  end
end
