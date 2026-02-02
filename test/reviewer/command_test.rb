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

    def test_uses_stored_seed_when_failed_keyword_present
      # Store a known seed
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, 42_424)
      arguments = Arguments.new(%w[failed])

      command = Reviewer::Command.new(:dynamic_seed_tool, :review, arguments: arguments)
      assert_equal 42_424, command.seed
    ensure
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, nil)
    end

    def test_generates_new_seed_when_failed_keyword_absent
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, 42_424)

      command = Reviewer::Command.new(:dynamic_seed_tool, :review)
      refute_equal 42_424, command.seed
    ensure
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, nil)
    end

    def test_generates_new_seed_when_failed_keyword_present_but_no_stored_seed
      arguments = Arguments.new(%w[failed])

      command = Reviewer::Command.new(:dynamic_seed_tool, :review, arguments: arguments)
      assert_kind_of Integer, command.seed
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
      arguments = Arguments.new(%w[-f lib/foo.rb,lib/bar.js,test/baz_test.rb])

      # Tool with *.rb pattern should only get .rb files
      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert_includes command.target_files, 'lib/foo.rb'
      assert_includes command.target_files, 'test/baz_test.rb'
      refute_includes command.target_files, 'lib/bar.js'
    end

    def test_target_files_returns_all_files_when_no_pattern
      # Set up arguments with mixed file types
      arguments = Arguments.new(%w[-f lib/foo.rb,lib/bar.js])

      # Tool without pattern should get all files
      command = Reviewer::Command.new(:file_targeting_tool, :review, arguments: arguments)

      assert_includes command.target_files, 'lib/foo.rb'
      assert_includes command.target_files, 'lib/bar.js'
    end

    def test_target_files_returns_empty_when_no_files_match_pattern
      # Set up arguments with only JS files
      arguments = Arguments.new(%w[-f lib/foo.js,lib/bar.js])

      # Tool with *.rb pattern should get no files
      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert_empty command.target_files
    end

    def test_target_files_filters_by_test_file_pattern
      # Set up arguments with mixed files
      arguments = Arguments.new(%w[-f lib/foo.rb,test/foo_test.rb,test/bar_test.rb])

      # Tool with *_test.rb pattern should only get test files
      command = Reviewer::Command.new(:test_pattern_tool, :review, arguments: arguments)

      assert_equal %w[test/bar_test.rb test/foo_test.rb], command.target_files.sort
    end

    def test_skip_returns_true_when_files_requested_but_none_match
      # Set up arguments with only JS files
      arguments = Arguments.new(%w[-f lib/foo.js,lib/bar.js])

      # Tool with *.rb pattern should skip (files requested but none match)
      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert command.skip?
    end

    def test_skip_returns_false_when_no_files_requested
      # No files requested - run tool normally
      arguments = Arguments.new([])

      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      refute command.skip?
    end

    def test_skip_returns_false_when_files_match_pattern
      # Set up arguments with Ruby files
      arguments = Arguments.new(%w[-f lib/foo.rb])

      # Tool with *.rb pattern should not skip (files match)
      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      refute command.skip?
    end

    def test_skip_returns_false_when_tool_has_no_pattern
      # Set up arguments with files
      arguments = Arguments.new(%w[-f lib/foo.rb])

      # Tool without pattern should not skip
      command = Reviewer::Command.new(:file_targeting_tool, :review, arguments: arguments)

      refute command.skip?
    end

    def test_target_files_maps_source_to_test_when_configured
      # Create temp directory with test file structure
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('test/models')
          FileUtils.touch('test/models/user_test.rb')

          # Set up arguments with source file
          arguments = Arguments.new(%w[-f app/models/user.rb])

          # Tool with map_to_tests: minitest should map source to test
          command = Reviewer::Command.new(:test_mapping_tool, :review, arguments: arguments)

          assert_equal ['test/models/user_test.rb'], command.target_files
        end
      end
    end

    def test_target_files_does_not_map_when_not_configured
      # Set up arguments with source file
      arguments = Arguments.new(%w[-f app/models/user.rb])

      # Tool without map_to_tests should pass files through (and filter by pattern)
      command = Reviewer::Command.new(:test_pattern_tool, :review, arguments: arguments)

      # Should be empty because app/models/user.rb doesn't match *_test.rb pattern
      assert_empty command.target_files
    end

    def test_target_files_passes_through_test_files_when_mapping_configured
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('test/models')
          FileUtils.touch('test/models/user_test.rb')

          # Set up arguments with test file directly
          arguments = Arguments.new(%w[-f test/models/user_test.rb])

          # Tool with map_to_tests should pass through existing test files
          command = Reviewer::Command.new(:test_mapping_tool, :review, arguments: arguments)

          assert_equal ['test/models/user_test.rb'], command.target_files
        end
      end
    end

    def test_uses_stored_failed_files_when_failed_keyword_and_no_explicit_files
      # Store failed files for this tool
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, %w[lib/reviewer/batch.rb lib/reviewer/command.rb])
      arguments = Arguments.new(%w[failed])

      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert_includes command.target_files, 'lib/reviewer/batch.rb'
      assert_includes command.target_files, 'lib/reviewer/command.rb'
    ensure
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_ignores_stored_files_when_explicit_files_provided
      # Store failed files
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, %w[lib/reviewer/batch.rb])
      arguments = Arguments.new(%w[failed -f lib/reviewer/command.rb])

      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert_includes command.target_files, 'lib/reviewer/command.rb'
      refute_includes command.target_files, 'lib/reviewer/batch.rb'
    ensure
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_returns_no_files_when_failed_keyword_and_no_stored_files
      arguments = Arguments.new(%w[failed])

      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert_empty command.target_files
    end

    def test_ignores_stored_files_without_failed_keyword
      # Store failed files but don't use the failed keyword
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, %w[lib/reviewer/batch.rb])
      arguments = Arguments.new([])

      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      # Without failed keyword, should run on everything (no file scoping)
      refute_includes command.send(:requested_files), 'lib/reviewer/batch.rb'
    ensure
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_skip_returns_true_when_mapped_test_does_not_exist
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # No test file exists
          arguments = Arguments.new(%w[-f app/models/user.rb])

          command = Reviewer::Command.new(:test_mapping_tool, :review, arguments: arguments)

          # Should skip because mapping found no existing test files
          assert command.skip?
        end
      end
    end

    def test_run_summary_returns_hash_when_not_skipped
      arguments = Arguments.new([])
      command = Reviewer::Command.new(:enabled_tool, :review, arguments: arguments)

      summary = command.run_summary

      assert_kind_of Hash, summary
      assert_equal 'Enabled Test Tool', summary[:name]
      assert_kind_of Array, summary[:files]
    end

    def test_run_summary_returns_nil_when_skipped
      arguments = Arguments.new(%w[-f lib/foo.js])
      command = Reviewer::Command.new(:file_pattern_tool, :review, arguments: arguments)

      assert_nil command.run_summary
    end
  end
end
