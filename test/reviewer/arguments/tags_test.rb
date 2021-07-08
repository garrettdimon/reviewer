# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class TagsTest < MiniTest::Test
      def test_array_casting
        assert_equal [], Tags.new.to_a
        assert_equal %w[css html ruby], Tags.new(provided: %w[css], keywords: %w[ruby html]).to_a
      end

      def test_string_casting
        assert_equal '', Tags.new.to_s
        assert_equal 'css,html,ruby', Tags.new(provided: %w[css], keywords: %w[ruby html]).to_s
      end

      def test_raw_aliases_provided
        tags = Tags.new
        assert_equal tags.provided, tags.raw
      end

      def test_generating_tags_from_flags
        tags_array = %w[ruby css]
        tags = Tags.new(
          provided: tags_array,
          keywords: []
        )

        assert_equal tags_array.sort, tags.to_a
      end

      def test_generating_tags_from_keywords
        keywords_array = %w[html]
        tags = Tags.new(
          provided: [],
          keywords: keywords_array
        )
        assert_equal keywords_array.sort, tags.to_a
      end

      def test_generating_tags_from_flags_and_keywords
        tags_array = %w[ruby css]
        keywords_array = %w[html]
        tags = Tags.new(
          provided: tags_array,
          keywords: keywords_array
        )
        tag_list = tags_array + keywords_array
        assert_equal tag_list.sort, tags.to_a
      end
    end
  end
end
