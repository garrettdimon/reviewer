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

      def test_exposes_configured_tools
        assert_equal Reviewer.configuration.tools.first, Keywords.configured_tools.first
      end

      def test_exposes_configured_tags
        first_tool_tags = Reviewer.configuration.tools.first[1].fetch(:tags)
        assert first_tool_tags.include?(Keywords.configured_tags[0])
      end

      def test_exposes_configured_tool_keys
        first_tool_key = Reviewer.configuration.tools.first[0]
        assert_equal first_tool_key, Keywords.configured_commands.first
      end

      def test_recognizes_reserved_keywords
        keywords_array = Keywords::RESERVED.sort
        keywords = Keywords.new(keywords_array)
        assert_equal keywords_array, keywords.provided
        assert_equal keywords_array, keywords.reserved
      end

      def test_recognizes_tag_keywords
        tag_keywords_array = [Keywords.configured_tags.first]
        keywords_array = (tag_keywords_array + ['noise']).sort
        keywords = Keywords.new(keywords_array)

        assert_equal keywords_array, keywords.provided
        assert_equal tag_keywords_array, keywords.for_tags
      end

      def test_recognizes_commands_keywords
        commands_keywords_array = [Keywords.configured_commands.first]
        keywords_array = (commands_keywords_array + ['noise']).sort
        keywords = Keywords.new(keywords_array)

        assert_equal keywords_array, keywords.provided
        assert_equal commands_keywords_array, keywords.for_commands
      end

      def test_exposes_all_possible_keywords
        keywords = Keywords.new(['one'])
        assert_equal %w[disabled disabled_tool dynamic_seed_tool enabled_tool failing_command fixture minimum_viable_tool missing_command staged test], keywords.possible
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
