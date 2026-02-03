# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Session
    class FormatterTest < Minitest::Test
      def formatter
        @formatter ||= Session::Formatter.new(Output.new)
      end

      def test_no_reviewable_files
        out, _err = capture_subprocess_io { formatter.no_reviewable_files(keywords: %w[staged]) }
        assert_match(/no.*staged.*files/i, out)
      end

      def test_no_reviewable_files_with_multiple_keywords
        out, _err = capture_subprocess_io { formatter.no_reviewable_files(keywords: %w[staged modified]) }
        assert_match(/staged/, out)
        assert_match(/modified/, out)
      end
    end
  end
end
