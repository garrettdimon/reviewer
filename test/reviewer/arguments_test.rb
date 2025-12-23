# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ArgumentsTest < Minitest::Test
    def test_has_an_empty_array_of_tags_by_default
      args = %w[]
      arguments = Arguments.new(args)
      assert_equal [], arguments.tags.raw
    end

    def test_parses_individual_tags_from_command_line
      args = %w[-t ruby]
      arguments = Arguments.new(args)
      assert_equal %w[ruby], arguments.tags.raw
    end

    def test_prints_version_information
      args = %w[-v]
      # rubocop:disable Lint/SuppressedException
      out, _err = capture_subprocess_io do
        Arguments.new(args)
      rescue SystemExit
      end
      # rubocop:enable Lint/SuppressedException
      assert_match(/#{Reviewer::VERSION}/i, out)
    end

    def test_prints_help_information
      args = %w[-h]
      # rubocop:disable Lint/SuppressedException
      out, _err = capture_subprocess_io do
        Arguments.new(args)
      rescue SystemExit
      end
      # rubocop:enable Lint/SuppressedException
      assert_match(/a list of comma/i, out)
    end

    def test_parses_multiple_tags_from_command_line
      args = %w[-t ruby,css]
      arguments = Arguments.new(args)
      assert_equal %w[ruby css], arguments.tags.raw
    end

    def test_has_an_empty_array_of_files_by_default
      args = %w[]
      arguments = Arguments.new(args)
      assert_equal [], arguments.files.raw
    end

    def test_parses_individual_files_from_command_line
      args = %w[-f ./app/**/*.rb]
      arguments = Arguments.new(args)
      assert_equal ['./app/**/*.rb'], arguments.files.raw
    end

    def test_parses_multiple_files_from_command_line
      args = %w[-f ./app/**/*.rb,./test/**/*.rb]
      arguments = Arguments.new(args)
      assert_equal ['./app/**/*.rb', './test/**/*.rb'], arguments.files.raw
    end

    def test_exposes_leftover_arguments_as_keywords
      args = %w[staged -t ruby invalid]
      arguments = Arguments.new(args)
      assert_equal %w[staged invalid], arguments.keywords.raw
    end

    def test_exposes_flagless_arguments_as_keywords
      args = %w[enabled_tool]
      arguments = Arguments.new(args)
      assert_equal args, arguments.keywords.raw
    end

    def test_gracefully_handles_robust_sets_of_arguments
      args = %w[staged --tags ruby,css --files ./app/**/*.rb,./test/**/*.rb]
      arguments = Arguments.new(args)
      assert_equal %w[staged], arguments.keywords.raw
      assert_equal %w[ruby css], arguments.tags.raw
      assert_equal ['./app/**/*.rb', './test/**/*.rb'], arguments.files.raw
    end

    def test_defines_custom_inspect
      args = %w[staged --tags ruby,css --files ./app/**/*.rb,./test/**/*.rb]
      arguments = Arguments.new(args)
      hash = arguments.inspect
      assert hash.key?(:files)
      assert hash.key?(:tags)
      assert hash.key?(:keywords)
    end
  end

  class ArgumentsFlagsTest < Minitest::Test
    def test_raw_is_false_by_default
      refute Arguments.new([]).raw?
    end

    def test_parses_short_raw_flag
      assert Arguments.new(%w[-r]).raw?
    end

    def test_parses_long_raw_flag
      assert Arguments.new(%w[--raw]).raw?
    end

    def test_raw_flag_works_with_other_options
      arguments = Arguments.new(%w[-r -t ruby staged])
      assert arguments.raw?
      assert_equal %w[ruby], arguments.tags.raw
    end

    def test_json_is_false_by_default
      refute Arguments.new([]).json?
    end

    def test_parses_short_json_flag
      assert Arguments.new(%w[-j]).json?
    end

    def test_parses_long_json_flag
      assert Arguments.new(%w[--json]).json?
    end

    def test_json_flag_works_with_other_options
      arguments = Arguments.new(%w[-j -t ruby staged])
      assert arguments.json?
      assert_equal %w[ruby], arguments.tags.raw
    end

    # --format flag tests
    def test_format_defaults_to_streaming
      assert_equal :streaming, Arguments.new([]).format
    end

    def test_parses_format_summary
      assert_equal :summary, Arguments.new(%w[--format summary]).format
    end

    def test_parses_format_json
      assert_equal :json, Arguments.new(%w[--format json]).format
    end

    def test_format_requires_long_flag
      # No short flag for --format; -m is not valid
      assert_raises(Slop::UnknownOption) { Arguments.new(%w[-m summary]) }
    end

    def test_json_flag_sets_format_to_json
      assert_equal :json, Arguments.new(%w[--json]).format
    end

    def test_format_flag_works_with_other_options
      arguments = Arguments.new(%w[--format summary -t ruby staged])
      assert_equal :summary, arguments.format
      assert_equal %w[ruby], arguments.tags.raw
    end

    # streaming? tests
    def test_streaming_true_by_default
      assert Arguments.new([]).streaming?
    end

    def test_streaming_false_for_summary_format
      refute Arguments.new(%w[--format summary]).streaming?
    end

    def test_streaming_false_for_json_format
      refute Arguments.new(%w[--format json]).streaming?
    end

    def test_streaming_false_for_json_flag
      refute Arguments.new(%w[--json]).streaming?
    end
  end
end
