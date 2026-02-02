# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class KeywordsTest < Minitest::Test
      def test_initializes_from_multiple_argument_formats
        keywords = Keywords.new('one')
        assert_equal ['one'], keywords.provided

        keywords = Keywords.new('one', 'two')
        assert_equal %w[one two].sort, keywords.provided

        keywords = Keywords.new(%w[one two])
        assert_equal %w[one two].sort, keywords.provided
      end

      def test_string_casting
        assert_equal '', Keywords.new.to_s
        assert_equal 'ruby,test', Keywords.new(%w[ruby test]).to_s
      end

      def test_casting_to_hash
        keywords = Keywords.new(tools: tools_collection)
        assert keywords.to_h.key?(:provided)
        assert keywords.to_h.key?(:for_tool_names)
      end

      def test_raw_aliases_provided
        keywords = Keywords.new
        assert_equal keywords.provided, keywords.raw
      end

      def test_exposes_configured_tags
        first_tool_tags = tools_collection.all.first.tags
        keywords = Keywords.new(tools: tools_collection)
        assert keywords.configured_tags.any?
        assert_equal first_tool_tags, (first_tool_tags & keywords.configured_tags)
      end

      def test_exposes_configured_tool_keys_as_name_strings
        first_tool_key = tools_collection.all.first.key.to_s
        keywords = Keywords.new(tools: tools_collection)
        assert_equal first_tool_key, keywords.configured_tool_names.first
      end

      def test_recognizes_reserved_keywords
        keywords_array = Keywords::RESERVED.sort
        keywords = Keywords.new(keywords_array)
        assert_equal keywords_array, keywords.provided
        assert_equal keywords_array, keywords.reserved
      end

      def test_recognizes_tag_keywords
        keywords = Keywords.new(tools: tools_collection)
        tag_keywords_array = [keywords.configured_tags.first]
        keywords_array = (tag_keywords_array + ['noise']).sort
        keywords = Keywords.new(keywords_array, tools: tools_collection)

        assert_equal keywords_array, keywords.provided
        assert_equal tag_keywords_array, keywords.for_tags
      end

      def test_recognizes_tool_names_keywords
        keywords = Keywords.new(tools: tools_collection)
        commands_keywords_array = [keywords.configured_tool_names.first]
        keywords_array = (commands_keywords_array + ['noise']).sort
        keywords = Keywords.new(keywords_array, tools: tools_collection)

        assert_equal keywords_array, keywords.provided
        assert_equal commands_keywords_array, keywords.for_tool_names
      end

      def test_exposes_all_possible_keywords_from_reserved
        keywords = Keywords.new(tools: tools_collection)
        assert keywords.possible.include?(Keywords::RESERVED.first)
        assert_equal Keywords::RESERVED.size, (keywords.possible & Keywords::RESERVED).size
      end

      def test_exposes_all_possible_keywords_from_configured_tags
        keywords = Keywords.new(tools: tools_collection)
        assert keywords.possible.include?(keywords.configured_tags.first)
        assert_equal keywords.configured_tags.size, (keywords.possible & keywords.configured_tags).size
      end

      def test_exposes_all_possible_keywords_from_configured_tool_names
        keywords = Keywords.new(tools: tools_collection)
        assert keywords.possible.include?(keywords.configured_tool_names.first)
        assert_equal keywords.configured_tool_names.size, (keywords.possible & keywords.configured_tool_names).size
      end

      def test_failed_is_a_reserved_keyword
        assert_includes Keywords::RESERVED, 'failed'

        keywords = Keywords.new('failed')
        assert_includes keywords.reserved, 'failed'
        assert_includes keywords.recognized, 'failed'
        assert_includes keywords.possible, 'failed'
      end

      def test_failed_predicate
        assert Keywords.new('failed').failed?
        refute Keywords.new('staged').failed?
        refute Keywords.new.failed?
      end

      def test_exposes_recognized_and_unrecognized_keywords
        unrecognized_keywords = ['unrecognized']
        keywords = Keywords.new(Keywords::RESERVED + unrecognized_keywords)
        assert_equal Keywords::RESERVED.sort, keywords.recognized
        assert_equal unrecognized_keywords, keywords.unrecognized
      end

      def test_uses_injected_tools_for_keyword_recognition
        keywords = Keywords.new('list', tools: tools_collection)
        assert_includes keywords.for_tool_names, 'list'
        assert_includes keywords.configured_tool_names, 'list'
      end

      def test_returns_empty_configured_tags_without_tools
        keywords = Keywords.new
        assert_equal [], keywords.configured_tags
      end

      def test_returns_empty_configured_tool_names_without_tools
        keywords = Keywords.new
        assert_equal [], keywords.configured_tool_names
      end

      private

      def tools_collection
        @tools_collection ||= Tools.new(history: Reviewer.history, config_file: Reviewer.configuration.file)
      end
    end
  end
end
