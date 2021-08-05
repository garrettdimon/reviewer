# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class String
      class VerbosityTest < MiniTest::Test
        def setup
          @flag = '--quiet'
          @verbosity = Verbosity.new(@flag)
        end

        def test_converts_to_a_string
          assert_equal @flag, @verbosity.to_s
        end

        def test_converts_to_array
          total_silence = Verbosity.new(@flag, level: :total_silence)
          assert_equal 2, total_silence.to_a.size
        end

        def test_includes_quiet_flag_for_total_silence
          verbosity = Verbosity.new(@flag, level: :total_silence)
          assert_includes verbosity.to_a, @flag
        end

        def test_includes_quiet_flag_for_tool_silence
          verbosity = Verbosity.new(@flag, level: :tool_silence)
          assert_includes verbosity.to_a, @flag
        end

        def test_does_not_include_quiet_flag_for_no_silence
          verbosity = Verbosity.new(@flag, level: :no_silence)
          refute_includes verbosity.to_a, @flag
        end

        def test_sends_to_dev_null_for_total_silence
          verbosity = Verbosity.new(@flag, level: :total_silence)
          assert_includes verbosity.to_a, Verbosity::SEND_TO_DEV_NULL
        end

        def test_does_not_send_to_dev_null_for_tool_silence
          verbosity = Verbosity.new(@flag, level: :tool_silence)
          refute_includes verbosity.to_a, Verbosity::SEND_TO_DEV_NULL
        end

        def test_does_not_send_to_dev_null_for_no_silence
          verbosity = Verbosity.new(@flag, level: :no_silence)
          refute_includes verbosity.to_a, Verbosity::SEND_TO_DEV_NULL
        end

        def test_adjusts_based_on_target_level
          total_silence = Verbosity.new(@flag, level: :total_silence)
          assert_equal "#{@flag} #{Verbosity::SEND_TO_DEV_NULL}", total_silence.to_s

          tool_silence = Verbosity.new(@flag, level: :tool_silence)
          assert_equal @flag, tool_silence.to_s

          no_silence = Verbosity.new(@flag, level: :no_silence)
          assert_equal '', no_silence.to_s
        end
      end
    end
  end
end
