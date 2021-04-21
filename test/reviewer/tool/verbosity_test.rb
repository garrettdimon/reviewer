# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Tool
    class VerbosityTest < MiniTest::Test
      def setup
        @flag = '--quiet'
        @verbosity = Reviewer::Tool::Verbosity.new(@flag)
      end

      def test_converts_to_a_string
        verbosity_string = "#{@flag} #{Verbosity::SEND_TO_DEV_NULL}"
        assert_equal verbosity_string, @verbosity.to_s
      end

      def test_converts_to_array
        total_silence = Reviewer::Tool::Verbosity.new(@flag, level: :total_silence)
        assert_equal 2, total_silence.to_a.size
      end

      def test_adjusts_based_on_target_level
        total_silence = Reviewer::Tool::Verbosity.new(@flag, level: :total_silence)
        assert_equal "#{@flag} #{Verbosity::SEND_TO_DEV_NULL}", total_silence.to_s

        tool_silence = Reviewer::Tool::Verbosity.new(@flag, level: :tool_silence)
        assert_equal @flag, tool_silence.to_s

        no_silence = Reviewer::Tool::Verbosity.new(@flag, level: :no_silence)
        assert_equal '', no_silence.to_s
      end

      def test_raises_error_if_level_is_invalid
        assert_raises(Verbosity::InvalidLevelError) do
          Reviewer::Tool::Verbosity.new(@flag, level: :quiet)
        end
      end
    end
  end
end
