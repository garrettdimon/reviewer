# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class KeywordsTest < MiniTest::Test
      def test_initializes_from_multiple_argument_formats
        keywords = Keywords.new('one')
        assert_equal ['one'], keywords.provided

        keywords = Keywords.new('one', 'two')
        assert_equal %w[one two].sort, keywords.provided

        keywords = Keywords.new(%w[one two])
        assert_equal %w[one two].sort, keywords.provided
      end

      def test_raw_aliases_provided
        keywords = Keywords.new
        assert_equal keywords.provided, keywords.raw
      end

      def test_exposes_configured_tags
        first_tool_tags = Reviewer.configuration.tools.first[1].fetch(:tags)
        keywords = Keywords.new
        assert keywords.configured_tags.any?
        assert_equal first_tool_tags, first_tool_tags.intersection(keywords.configured_tags)
      end

      def test_exposes_configured_tool_names
        first_tool_key = Reviewer.configuration.tools.first[0]
        keywords = Keywords.new
        assert_equal first_tool_key, keywords.configured_tool_names.first
      end

      def test_recognizes_reserved_keywords
        keywords_array = Keywords::RESERVED.sort
        keywords = Keywords.new(keywords_array)
        assert_equal keywords_array, keywords.provided
        assert_equal keywords_array, keywords.reserved
      end

      def test_recognizes_tag_keywords
        keywords = Keywords.new
        tag_keywords_array = [keywords.configured_tags.first]
        keywords_array = (tag_keywords_array + ['noise']).sort
        keywords = Keywords.new(keywords_array)

        assert_equal keywords_array, keywords.provided
        assert_equal tag_keywords_array, keywords.for_tags
      end

      def test_recognizes_tool_names_keywords
        keywords = Keywords.new
        commands_keywords_array = [keywords.configured_tool_names.first]
        keywords_array = (commands_keywords_array + ['noise']).sort
        keywords = Keywords.new(keywords_array)

        assert_equal keywords_array, keywords.provided
        assert_equal commands_keywords_array, keywords.for_tool_names
      end

      def test_exposes_all_possible_keywords
        keywords = Keywords.new

        assert keywords.possible.include?(Keywords::RESERVED.first)
        assert_equal Keywords::RESERVED.size, keywords.possible.intersection(Keywords::RESERVED).size

        assert keywords.possible.include?(keywords.configured_tags.first)
        assert_equal keywords.configured_tags.size, keywords.possible.intersection(keywords.configured_tags).size

        assert keywords.possible.include?(keywords.configured_tool_names.first)
        assert_equal keywords.configured_tool_names.size, keywords.possible.intersection(keywords.configured_tool_names).size
      end

      def test_exposes_recognized_and_unrecognized_keywords
        unrecognized_keywords = ['unrecognized']
        keywords = Keywords.new(Keywords::RESERVED + unrecognized_keywords)
        assert_equal Keywords::RESERVED, keywords.recognized
        assert_equal unrecognized_keywords, keywords.unrecognized
      end
    end
  end
end
