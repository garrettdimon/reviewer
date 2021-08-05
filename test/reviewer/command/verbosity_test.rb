# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class VerbosityTest < MiniTest::Test
      def setup
        @total = Reviewer::Command::Verbosity.new(:total_silence)
        @tool = Reviewer::Command::Verbosity.new(:tool_silence)
        @no = Reviewer::Command::Verbosity.new(:no_silence)
      end

      def test_initializes_with_string_or_symbol
        value = 'total_silence'
        verbosity = Reviewer::Command::Verbosity.new(value)
        assert_equal value.to_sym, verbosity.to_sym
      end

      def test_converts_to_symbol
        assert_equal :total_silence, @total.key
        assert_equal :tool_silence, @tool.key
        assert_equal :no_silence, @no.key
      end

      def test_converts_to_string
        assert_equal 'total_silence', @total.to_s
        assert_equal 'tool_silence', @tool.to_s
        assert_equal 'no_silence', @no.to_s
      end

      def test_converts_to_integer
        assert_equal 0, @total.to_i
        assert_equal 1, @tool.to_i
        assert_equal 2, @no.to_i
      end

      def test_raises_error_if_level_is_invalid
        assert_raises(Reviewer::Command::Verbosity::InvalidLevelError) do
          Reviewer::Command::Verbosity.new(:quiet)
        end
      end
    end
  end
end
