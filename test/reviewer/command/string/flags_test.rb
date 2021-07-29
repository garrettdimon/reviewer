# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class String
      class FlagsTest < MiniTest::Test
        def setup
          @flag_pairs = {
            f: true,
            n: nil,
            e: '',
            format: false,
            nil: nil,
            empty: ''
          }
          @flags = Reviewer::Command::String::Flags.new(@flag_pairs)
        end

        def test_casts_to_a_string
          flags_string = '-f true -n -e --format false --nil --empty'
          assert_equal flags_string, @flags.to_s
        end

        def test_properly_format_single_letter_flags
          assert_includes @flags.to_a, '-f true'
          assert_includes @flags.to_a, '-n'
          assert_includes @flags.to_a, '-e'
        end

        def test_properly_format_multiple_letter_flags
          assert_includes @flags.to_a, '--format false'
          assert_includes @flags.to_a, '--empty'
          assert_includes @flags.to_a, '--nil'
        end
      end
    end
  end
end
