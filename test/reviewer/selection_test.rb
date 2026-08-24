# frozen_string_literal: true

require 'test_helper'

module Reviewer
  # Selection is the contract between what a caller asks for and what runs.
  # A name Reviewer does not recognize must never resolve to "everything".
  #
  # The fixture's `disabled_tool` is skip_in_batch and carries the `html` tag,
  # which no batch-enabled tool has -- the case where a tag is real but invisible
  # to any dictionary built from the enabled set.
  class SelectionTest < Minitest::Test
    def setup
      @config = Reviewer.configuration.file
    end

    def test_tagged_does_not_mutate_the_memoized_enabled_collection
      tools = Tools.new(config_file: @config, tags: ['ruby'])
      before = tools.enabled.size

      tools.tagged

      assert_equal before, tools.enabled.size,
                   'Expected #tagged to filter a copy, not shrink the memoized collection'
    end

    def test_a_tag_carried_only_by_a_skipped_tool_is_still_recognized
      keywords = Arguments::Keywords.new(['html'])
      keywords.tools = Tools.new(config_file: @config)

      assert_includes keywords.possible, 'html',
                      'Expected tags on skip_in_batch tools to be recognizable selectors'
      assert_empty keywords.unrecognized
    end

    def test_a_tag_carried_only_by_a_skipped_tool_resolves_to_nothing_rather_than_everything
      tools = Tools.new(config_file: @config, tags: ['html'])

      # `skip_in_batch` means "only when named", so an empty set is correct here.
      # What matters is that it is empty rather than the full batch -- the caller
      # asked for something specific and must not silently get everything.
      assert_empty tools.current
      refute_equal tools.enabled.size, tools.current.size
    end

    def test_an_unrecognized_name_is_reported_as_such
      keywords = Arguments::Keywords.new(['rubocp'])
      keywords.tools = Tools.new(config_file: @config)

      assert_equal %w[rubocp], keywords.unrecognized
    end
  end
end
