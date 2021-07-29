# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class String
      class VerbosityTest < MiniTest::Test
        def setup
          @flag = '--quiet'
          @verbosity = Reviewer::Command::String::Verbosity.new(@flag)
        end

        def test_converts_to_a_string
          assert_equal @flag, @verbosity.to_s
        end

        def test_converts_to_array
          total_silence = Reviewer::Command::String::Verbosity.new(@flag, level: :total_silence)
          assert_equal 2, total_silence.to_a.size
        end

        def test_adjusts_based_on_target_level
          total_silence = Reviewer::Command::String::Verbosity.new(@flag, level: :total_silence)
          assert_equal "#{@flag} #{Reviewer::Command::String::Verbosity::SEND_TO_DEV_NULL}", total_silence.to_s

          tool_silence = Reviewer::Command::String::Verbosity.new(@flag, level: :tool_silence)
          assert_equal @flag, tool_silence.to_s

          no_silence = Reviewer::Command::String::Verbosity.new(@flag, level: :no_silence)
          assert_equal '', no_silence.to_s
        end
      end
    end
  end
end
