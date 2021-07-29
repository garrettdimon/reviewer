# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class CommandTest < MiniTest::Test
    def setup
      @command = Reviewer::Command.new(:enabled_tool, :review, :no_silence)
    end

    def test_knows_when_a_command_uses_a_random_seed
      skip "Pending Test"
    end

    def test_can_be_cast_to_string
      skip "infinite loop"
      command_string = "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true bundle exec example review --third 'third flag' --fourth 'fourth flag'"

      assert_equal command_string, @command.string
      assert_equal @command.string, @command.to_s
    end

    def test_defaults_verbosity_to_total_silence
      skip "Pending Test"
    end

    def test_raises_error_on_invalid_command_type
      skip "Pending Test"
    end

    def test_raises_error_if_command_type_is_not_defined_for_tool
      skip "Pending Test"
    end
  end
end
