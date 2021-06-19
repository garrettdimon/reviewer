# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class TagsTest < MiniTest::Test
      def setup
        @tags_array = %w[ruby css]
        @keywords_array = %w[html]
        @tags = Tags.new(
          provided: @tags_array,
          keywords: @keywords_array
        )
      end

      def test_generating_tags_from_flags
        skip 'TODO'
        # files = ::Reviewer::Arguments::Files.new
        # assert_equal ::Reviewer.arguments.files, files.files
        # assert_equal ::Reviewer.arguments.keywords, files.keywords
      end

      def test_generating_tags_from_keywords
        skip 'TODO'
        # files = ::Reviewer::Arguments::Files.new
        # assert_equal ::Reviewer.arguments.files, files.files
        # assert_equal ::Reviewer.arguments.keywords, files.keywords
      end
    end
  end
end
