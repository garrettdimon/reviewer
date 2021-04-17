# frozen_string_literal: true

require "test_helper"

module Reviewer
  class CommandTest < MiniTest::Test
    def setup
    end

    def test_has_an_empty_array_of_tags_by_default
      args = %w{}
      command = Command.new(args)
      assert_equal [], command.tags
    end

    def test_parses_individual_tags_from_command_line
      args = %w{-t ruby}
      command = Command.new(args)
      assert_equal ["ruby"], command.tags
    end

    def test_parses_multiple_tags_from_command_line
      args = %w{-t ruby,css}
      command = Command.new(args)
      assert_equal ["ruby", "css"], command.tags
    end

    def test_has_an_empty_array_of_files_by_default
      args = %w{}
      command = Command.new(args)
      assert_equal [], command.files
    end

    def test_parses_individual_files_from_command_line
      args = %w{-f ./app/**/*.rb}
      command = Command.new(args)
      assert_equal ["./app/**/*.rb"], command.files
    end

    def test_parses_multiple_files_from_command_line
      args = %w{-f ./app/**/*.rb,./test/**/*.rb}
      command = Command.new(args)
      assert_equal ["./app/**/*.rb","./test/**/*.rb"], command.files
    end

    def test_exposes_leftover_arguments_as_keywords
      args = %w{first -t ruby second}
      command = Command.new(args)
      assert_equal ["first", "second"], command.arguments
      assert_equal ["first", "second"], command.keywords
    end

    def test_gracefully_handles_robust_sets_of_arguments
      args = %w{keyword --tags ruby,css --files ./app/**/*.rb,./test/**/*.rb }
      command = Command.new(args)
      assert_equal ["keyword"], command.arguments
      assert_equal ["keyword"], command.keywords
      assert_equal ["ruby", "css"], command.tags
      assert_equal ["./app/**/*.rb","./test/**/*.rb"], command.files
    end
  end
end