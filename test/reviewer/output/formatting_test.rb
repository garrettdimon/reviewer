# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Output
    class FormattingTest < Minitest::Test
      include Formatting

      def test_format_duration_with_value
        assert_equal '1.23s', format_duration(1.234)
      end

      def test_format_duration_with_nil
        assert_equal '0.0s', format_duration(nil)
      end

      def test_status_mark_success
        assert_equal Formatting::CHECKMARK, status_mark(true)
      end

      def test_status_mark_failure
        assert_equal Formatting::XMARK, status_mark(false)
      end

      def test_status_style_success
        assert_equal :success, status_style(true)
      end

      def test_status_style_failure
        assert_equal :failure, status_style(false)
      end

      def test_pluralize_singular
        assert_equal '1 issue', pluralize(1, 'issue')
      end

      def test_pluralize_plural
        assert_equal '3 issues', pluralize(3, 'issue')
      end

      def test_pluralize_custom_plural
        assert_equal '2 children', pluralize(2, 'child', 'children')
      end

      def test_pluralize_zero
        assert_equal '0 issues', pluralize(0, 'issue')
      end
    end
  end
end
