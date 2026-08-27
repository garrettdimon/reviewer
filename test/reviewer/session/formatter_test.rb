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

      def test_unrecognized_keywords_json_uses_the_error_envelope # rubocop:disable Metrics/AbcSize
        out, _err = capture_subprocess_io do
          formatter.unrecognized_keywords_json(['lsit'], 'lsit' => 'list')
        end
        parsed = JSON.parse(out)

        assert_equal 1, parsed['schema_version']
        assert_equal 'error', parsed['state']
        refute parsed.key?('success')
        refute parsed.key?('message')
        assert_equal 'unrecognized_selector', parsed.dig('error', 'code')
        assert_equal(
          {
            'total' => 0, 'passed' => 0, 'failed' => 0, 'skipped' => 0,
            'missing' => 0, 'not_run' => 0, 'duration' => 0
          },
          parsed['summary']
        )
        assert_empty parsed['tools']
      end
    end
  end
end
