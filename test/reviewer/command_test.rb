# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class CommandTest < MiniTest::Test
    def setup
      @command = Reviewer::Command.new(:enabled_tool, :review, :no_silence)
    end

    def test_maintains_seed_despite_changes
      original_seed = @command.seed
      @command.verbosity = Command::Verbosity::TOTAL_SILENCE
      assert_equal original_seed, @command.seed
    end

    def test_records_last_used_seed_in_history
      seed = @command.seed
      assert_equal seed, Reviewer.history.get(@command.tool.key, :last_seed)
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
      assert_equal Command::Verbosity::NO_SILENCE, @command.verbosity.level

      @command.verbosity = Command::Verbosity::TOTAL_SILENCE
      assert_equal Command::Verbosity::TOTAL_SILENCE, @command.verbosity.level
    end
  end
end
