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

    def build_session(arguments:)
      tools = Tools.new(config_file: @config, arguments: arguments, history: Reviewer.history)
      arguments.keywords.tools = tools
      context = Context.new(arguments: arguments, output: Output.new, history: Reviewer.history)
      Session.new(context: context, tools: tools)
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

    # Passing tags: directly sets @tags and bypasses #matching_tags, which is the
    # method that decides what a *positional* tag resolves to. Go through
    # Arguments so the path a caller actually takes is the path under test.
    def test_a_tag_carried_only_by_a_skipped_tool_resolves_to_nothing_rather_than_everything
      arguments = Arguments.new(['html'])
      tools = Tools.new(config_file: @config, arguments: arguments, history: Reviewer.history)
      arguments.keywords.tools = tools

      # `skip_in_batch` means "only when named", so an empty set is correct here.
      # What matters is that it is empty rather than the full batch -- the caller
      # asked for something specific and must not silently get everything.
      assert_empty tools.current
      refute_equal tools.enabled.size, tools.current.size
    end

    # Three places have listed the reserved keywords independently, and the
    # capabilities payload drifted from the other two by omitting `failed`.
    def test_the_help_text_lists_every_reserved_keyword
      help, = capture_subprocess_io { Reviewer.send(:show_help) }

      Arguments::Keywords::RESERVED.each do |keyword|
        assert_includes help, keyword, "Expected --help to document the `#{keyword}` keyword"
      end
    end

    # `-t` is the path tooling uses, so an unknown tag there has to behave the
    # same as an unknown positional rather than silently selecting nothing.
    def test_an_unrecognized_tag_via_the_flag_runs_nothing_and_exits_two
      status = nil
      out, = capture_subprocess_io do
        status = build_session(arguments: Arguments.new(%w[-t zzznope --json])).review
      end

      assert_equal 2, status
      payload = JSON.parse(out)

      assert_equal 'unrecognized_selector', payload.dig('error', 'code')
      assert_includes payload.dig('error', 'message'), 'zzznope'
    end

    def test_a_recognized_tag_via_the_flag_still_runs
      status = nil
      capture_subprocess_io do
        status = build_session(arguments: Arguments.new(%w[-t ruby --json])).review
      end

      refute_equal 2, status, 'A configured tag must not be treated as a usage error'
    end

    def test_an_unrecognized_name_is_reported_as_such
      keywords = Arguments::Keywords.new(['rubocp'])
      keywords.tools = Tools.new(config_file: @config)

      assert_equal %w[rubocp], keywords.unrecognized
    end

    # The whole point: a name Reviewer does not know must stop the run, in both
    # output modes, rather than quietly resolving to the full batch.
    def test_an_unrecognized_name_runs_nothing_and_exits_two_in_text_mode
      status = nil
      out, = capture_subprocess_io do
        status = build_session(arguments: Arguments.new(%w[rubocp])).review
      end

      assert_equal 2, status, 'A usage error is exit 2, distinct from a tool failure'
      assert_match(/rubocp/, out)
      refute_match(/Success/i, out)
    end

    def test_an_unrecognized_name_runs_nothing_and_exits_two_in_json_mode
      status = nil
      out, = capture_subprocess_io do
        status = build_session(arguments: Arguments.new(%w[rubocp --json])).review
      end

      assert_equal 2, status
      payload = JSON.parse(out)

      assert_equal 'error', payload['state']
      assert_equal 'unrecognized_selector', payload.dig('error', 'code')
      assert_includes payload.dig('error', 'message'), 'rubocp'
      assert_empty payload['tools']
    end
  end
end
