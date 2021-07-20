# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ArgumentsTest < MiniTest::Test
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
      out, _err = capture_subprocess_io do
        Arguments.new(args)
      rescue SystemExit
      end
      assert_match(/#{Reviewer::VERSION}/i, out)
    end

    def test_prints_help_information
      args = %w[-h]
      out, _err = capture_subprocess_io do
        Arguments.new(args)
      rescue SystemExit
      end
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
end
