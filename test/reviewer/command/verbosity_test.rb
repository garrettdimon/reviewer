# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class VerbosityTest < MiniTest::Test
      def setup
        @total = Reviewer::Command::Verbosity.new(:silent)
        @tool = Reviewer::Command::Verbosity.new(:quiet)
        @no = Reviewer::Command::Verbosity.new(:verbose)
      end

      def test_initializes_with_string_or_symbol
        value = 'silent'
        verbosity = Reviewer::Command::Verbosity.new(value)
        assert_equal value.to_sym, verbosity.to_sym
      end

      def test_converts_to_symbol
        assert_equal :silent, @total.key
        assert_equal :quiet, @tool.key
        assert_equal :verbose, @no.key
      end

      def test_converts_to_string
        assert_equal 'silent', @total.to_s
        assert_equal 'quiet', @tool.to_s
        assert_equal 'verbose', @no.to_s
      end

      def test_converts_to_integer
        assert_equal 0, @total.to_i
        assert_equal 1, @tool.to_i
        assert_equal 2, @no.to_i
      end

      def test_raises_error_if_level_is_invalid
        assert_raises(Reviewer::Command::Verbosity::InvalidLevelError) do
          Reviewer::Command::Verbosity.new(:talkative)
        end
      end
    end
  end
end
