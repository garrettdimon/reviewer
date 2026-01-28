# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Output
    class ScrubTest < Minitest::Test
      def test_removes_rake_aborted_and_following_text
        raw = "useful error\nrake aborted!\nunhelpful noise"

        assert_equal "useful error\n", Output.scrub(raw)
      end

      def test_preserves_clean_text
        clean = 'some text without rake aborted'

        assert_equal clean, Output.scrub(clean)
      end

      def test_handles_nil
        assert_equal '', Output.scrub(nil)
      end
    end
  end
end
