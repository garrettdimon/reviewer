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
          silent = Verbosity.new(@flag, level: :silent)
          assert_equal 2, silent.to_a.size
        end

        def test_includes_quiet_flag_for_silent
          verbosity = Verbosity.new(@flag, level: :silent)
          assert_includes verbosity.to_a, @flag
        end

        def test_includes_quiet_flag_for_quiet
          verbosity = Verbosity.new(@flag, level: :quiet)
          assert_includes verbosity.to_a, @flag
        end

        def test_does_not_include_quiet_flag_for_verbose
          verbosity = Verbosity.new(@flag, level: :verbose)
          refute_includes verbosity.to_a, @flag
        end

        def test_sends_to_dev_null_for_silent
          verbosity = Verbosity.new(@flag, level: :silent)
          assert_includes verbosity.to_a, Verbosity::SEND_TO_DEV_NULL
        end

        def test_does_not_send_to_dev_null_for_quiet
          verbosity = Verbosity.new(@flag, level: :quiet)
          refute_includes verbosity.to_a, Verbosity::SEND_TO_DEV_NULL
        end

        def test_does_not_send_to_dev_null_for_verbose
          verbosity = Verbosity.new(@flag, level: :verbose)
          refute_includes verbosity.to_a, Verbosity::SEND_TO_DEV_NULL
        end

        def test_adjusts_based_on_target_level
          silent = Verbosity.new(@flag, level: :silent)
          assert_equal "#{@flag} #{Verbosity::SEND_TO_DEV_NULL}", silent.to_s

          quiet = Verbosity.new(@flag, level: :quiet)
          assert_equal @flag, quiet.to_s

          verbose = Verbosity.new(@flag, level: :verbose)
          assert_equal '', verbose.to_s
        end
      end
    end
  end
end
