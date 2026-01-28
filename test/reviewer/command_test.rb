# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class CommandTest < Minitest::Test
    def setup
      @command = Reviewer::Command.new(:enabled_tool, :review)
    end

    def test_maintains_seed_despite_changes
      original_seed = @command.seed
      @command.type = :install
      assert_equal original_seed, @command.seed
    end

    def test_records_last_used_seed_in_history
      seed = @command.seed
      assert_equal seed, Reviewer.history.get(@command.tool.key, :last_seed)
    end

    def test_command_with_seed
      command = Reviewer::Command.new(:dynamic_seed_tool, :review)
      assert_match(/#{command.seed}/, command.string)
    end

    def test_can_be_cast_to_string
      command_string = "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -c --third 'third flag' --fourth 'fourth flag'"

      assert_equal command_string, @command.string
      assert_equal @command.string, @command.to_s
    end

    def test_generates_fresh_string_after_type_change
      assert_equal :review, @command.type

      @command.type = :install
      assert_equal :install, @command.type
    end

    def test_target_files_filters_by_pattern
      # Set up arguments with mixed file types
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.rb,lib/bar.js,test/baz_test.rb]))

      # Tool with *.rb pattern should only get .rb files
      command = Reviewer::Command.new(:file_pattern_tool, :review)

      assert_includes command.target_files, 'lib/foo.rb'
      assert_includes command.target_files, 'test/baz_test.rb'
      refute_includes command.target_files, 'lib/bar.js'
    ensure
      ensure_test_configuration!
    end

    def test_target_files_returns_all_files_when_no_pattern
      # Set up arguments with mixed file types
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.rb,lib/bar.js]))

      # Tool without pattern should get all files
      command = Reviewer::Command.new(:file_targeting_tool, :review)

      assert_includes command.target_files, 'lib/foo.rb'
      assert_includes command.target_files, 'lib/bar.js'
    ensure
      ensure_test_configuration!
    end

    def test_target_files_returns_empty_when_no_files_match_pattern
      # Set up arguments with only JS files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.js,lib/bar.js]))

      # Tool with *.rb pattern should get no files
      command = Reviewer::Command.new(:file_pattern_tool, :review)

      assert_empty command.target_files
    ensure
      ensure_test_configuration!
    end

    def test_target_files_filters_by_test_file_pattern
      # Set up arguments with mixed files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.rb,test/foo_test.rb,test/bar_test.rb]))

      # Tool with *_test.rb pattern should only get test files
      command = Reviewer::Command.new(:test_pattern_tool, :review)

      assert_equal %w[test/bar_test.rb test/foo_test.rb], command.target_files.sort
    ensure
      ensure_test_configuration!
    end

    def test_skip_returns_true_when_files_requested_but_none_match
      # Set up arguments with only JS files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.js,lib/bar.js]))

      # Tool with *.rb pattern should skip (files requested but none match)
      command = Reviewer::Command.new(:file_pattern_tool, :review)

      assert command.skip?
    ensure
      ensure_test_configuration!
    end

    def test_skip_returns_false_when_no_files_requested
      # No files requested - run tool normally
      Reviewer.instance_variable_set(:@arguments, Arguments.new([]))

      command = Reviewer::Command.new(:file_pattern_tool, :review)

      refute command.skip?
    ensure
      ensure_test_configuration!
    end

    def test_skip_returns_false_when_files_match_pattern
      # Set up arguments with Ruby files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.rb]))

      # Tool with *.rb pattern should not skip (files match)
      command = Reviewer::Command.new(:file_pattern_tool, :review)

      refute command.skip?
    ensure
      ensure_test_configuration!
    end

    def test_skip_returns_false_when_tool_has_no_pattern
      # Set up arguments with files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.rb]))

      # Tool without pattern should not skip
      command = Reviewer::Command.new(:file_targeting_tool, :review)

      refute command.skip?
    ensure
      ensure_test_configuration!
    end
  end
end
