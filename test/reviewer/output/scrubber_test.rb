# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Output
    class ScrubberTest < Minitest::Test
      def test_scrubs_rake_aborted_content
        raw_stderr = <<~STDERR
          some text before

          rake aborted!
          some text after
        STDERR

        scrubber = Reviewer::Output::Scrubber.new(raw_stderr)

        assert_match(/rake aborted/, scrubber.raw)
        refute_match(/rake aborted/, scrubber.clean)
        refute_match(/some text after rake aborted/, scrubber.clean)
      end

      def test_does_not_modify_untainted_text
        clean_stderr = <<~STDERR
          some text without 'Rake Aborted' text
        STDERR

        scrubber = Reviewer::Output::Scrubber.new(clean_stderr)
        assert_equal clean_stderr, scrubber.clean
      end

      def test_safely_handles_nil_values
        scrubber = Reviewer::Output::Scrubber.new(nil)
        assert_equal '', scrubber.clean
      end
    end
  end
end
