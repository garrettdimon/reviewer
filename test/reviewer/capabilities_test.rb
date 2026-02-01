# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class CapabilitiesTest < Minitest::Test
    def setup
      @capabilities = Capabilities.new
    end

    def test_to_h_returns_hash
      result = @capabilities.to_h
      assert_kind_of Hash, result
    end

    def test_includes_version
      result = @capabilities.to_h
      assert_equal Reviewer::VERSION, result[:version]
    end

    def test_includes_tools_array
      result = @capabilities.to_h
      assert_kind_of Array, result[:tools]
    end

    def test_tools_have_required_keys
      result = @capabilities.to_h
      tool = result[:tools].first
      assert tool.key?(:key), 'Tool should have :key'
      assert tool.key?(:name), 'Tool should have :name'
      assert tool.key?(:description), 'Tool should have :description'
      assert tool.key?(:tags), 'Tool should have :tags'
      assert tool.key?(:skip_in_batch), 'Tool should have :skip_in_batch'
      assert tool.key?(:commands), 'Tool should have :commands'
    end

    def test_tool_commands_include_review_and_format
      result = @capabilities.to_h
      tool = result[:tools].first
      assert tool[:commands].key?(:review), 'Commands should have :review'
      assert tool[:commands].key?(:format), 'Commands should have :format'
    end

    def test_tool_key_is_string
      result = @capabilities.to_h
      tool = result[:tools].first
      assert_kind_of String, tool[:key]
    end

    def test_includes_keywords
      result = @capabilities.to_h
      assert_kind_of Hash, result[:keywords]
      assert result[:keywords].key?(:staged)
      assert result[:keywords].key?(:unstaged)
      assert result[:keywords].key?(:modified)
      assert result[:keywords].key?(:untracked)
    end

    def test_includes_scenarios
      result = @capabilities.to_h
      assert_kind_of Hash, result[:scenarios]
      assert result[:scenarios].key?(:before_commit)
      assert result[:scenarios].key?(:during_development)
      assert result[:scenarios].key?(:full_review)
    end

    def test_to_json_returns_string
      result = @capabilities.to_json
      assert_kind_of String, result
    end

    def test_to_json_is_valid_json
      result = @capabilities.to_json
      parsed = JSON.parse(result)
      assert_kind_of Hash, parsed
    end

    def test_to_json_matches_to_h
      json = @capabilities.to_json
      parsed = JSON.parse(json, symbolize_names: true)
      assert_equal @capabilities.to_h, parsed
    end
  end
end
