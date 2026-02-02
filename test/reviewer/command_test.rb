# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class CommandTest < Minitest::Test
    def setup
      @command = Reviewer::Command.new(:enabled_tool, :review, context: default_context)
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
      command = Reviewer::Command.new(:dynamic_seed_tool, :review, context: default_context)
      assert_match(/#{command.seed}/, command.string)
    end

    def test_uses_stored_seed_when_failed_keyword_present
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, 42_424)
      context = default_context(arguments: Arguments.new(%w[failed]))

      command = Reviewer::Command.new(:dynamic_seed_tool, :review, context: context)
      assert_equal 42_424, command.seed
    ensure
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, nil)
    end

    def test_generates_new_seed_when_failed_keyword_absent
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, 42_424)

      command = Reviewer::Command.new(:dynamic_seed_tool, :review, context: default_context)
      refute_equal 42_424, command.seed
    ensure
      Reviewer.history.set(:dynamic_seed_tool, :last_seed, nil)
    end

    def test_generates_new_seed_when_failed_keyword_present_but_no_stored_seed
      context = default_context(arguments: Arguments.new(%w[failed]))

      command = Reviewer::Command.new(:dynamic_seed_tool, :review, context: context)
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
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.rb,lib/bar.js,test/baz_test.rb]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert_includes command.target_files, 'lib/foo.rb'
      assert_includes command.target_files, 'test/baz_test.rb'
      refute_includes command.target_files, 'lib/bar.js'
    end

    def test_target_files_returns_all_files_when_no_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.rb,lib/bar.js]))

      command = Reviewer::Command.new(:file_targeting_tool, :review, context: context)

      assert_includes command.target_files, 'lib/foo.rb'
      assert_includes command.target_files, 'lib/bar.js'
    end

    def test_target_files_returns_empty_when_no_files_match_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.js,lib/bar.js]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert_empty command.target_files
    end

    def test_target_files_filters_by_test_file_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.rb,test/foo_test.rb,test/bar_test.rb]))

      command = Reviewer::Command.new(:test_pattern_tool, :review, context: context)

      assert_equal %w[test/bar_test.rb test/foo_test.rb], command.target_files.sort
    end

    def test_skip_returns_true_when_files_requested_but_none_match
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.js,lib/bar.js]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert command.skip?
    end

    def test_skip_returns_false_when_no_files_requested
      context = default_context(arguments: Arguments.new([]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      refute command.skip?
    end

    def test_skip_returns_false_when_files_match_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.rb]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      refute command.skip?
    end

    def test_skip_returns_false_when_tool_has_no_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.rb]))

      command = Reviewer::Command.new(:file_targeting_tool, :review, context: context)

      refute command.skip?
    end

    def test_target_files_maps_source_to_test_when_configured
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('test/models')
          FileUtils.touch('test/models/user_test.rb')

          context = default_context(arguments: Arguments.new(%w[-f app/models/user.rb]))

          command = Reviewer::Command.new(:test_mapping_tool, :review, context: context)

          assert_equal ['test/models/user_test.rb'], command.target_files
        end
      end
    end

    def test_target_files_does_not_map_when_not_configured
      context = default_context(arguments: Arguments.new(%w[-f app/models/user.rb]))

      command = Reviewer::Command.new(:test_pattern_tool, :review, context: context)

      assert_empty command.target_files
    end

    def test_target_files_passes_through_test_files_when_mapping_configured
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('test/models')
          FileUtils.touch('test/models/user_test.rb')

          context = default_context(arguments: Arguments.new(%w[-f test/models/user_test.rb]))

          command = Reviewer::Command.new(:test_mapping_tool, :review, context: context)

          assert_equal ['test/models/user_test.rb'], command.target_files
        end
      end
    end

    def test_uses_stored_failed_files_when_failed_keyword_and_no_explicit_files
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, %w[lib/reviewer/batch.rb lib/reviewer/command.rb])
      context = default_context(arguments: Arguments.new(%w[failed]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert_includes command.target_files, 'lib/reviewer/batch.rb'
      assert_includes command.target_files, 'lib/reviewer/command.rb'
    ensure
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_ignores_stored_files_when_explicit_files_provided
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, %w[lib/reviewer/batch.rb])
      context = default_context(arguments: Arguments.new(%w[failed -f lib/reviewer/command.rb]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert_includes command.target_files, 'lib/reviewer/command.rb'
      refute_includes command.target_files, 'lib/reviewer/batch.rb'
    ensure
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_returns_no_files_when_failed_keyword_and_no_stored_files
      context = default_context(arguments: Arguments.new(%w[failed]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert_empty command.target_files
    end

    def test_ignores_stored_files_without_failed_keyword
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, %w[lib/reviewer/batch.rb])
      context = default_context(arguments: Arguments.new([]))

      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      refute_includes command.send(:requested_files), 'lib/reviewer/batch.rb'
    ensure
      Reviewer.history.set(:file_pattern_tool, :last_failed_files, nil)
    end

    def test_skip_returns_true_when_mapped_test_does_not_exist
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          context = default_context(arguments: Arguments.new(%w[-f app/models/user.rb]))

          command = Reviewer::Command.new(:test_mapping_tool, :review, context: context)

          assert command.skip?
        end
      end
    end

    def test_run_summary_returns_hash_when_not_skipped
      context = default_context(arguments: Arguments.new([]))
      command = Reviewer::Command.new(:enabled_tool, :review, context: context)

      summary = command.run_summary

      assert_kind_of Hash, summary
      assert_equal 'Enabled Test Tool', summary[:name]
      assert_kind_of Array, summary[:files]
    end

    def test_run_summary_returns_nil_when_skipped
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.js]))
      command = Reviewer::Command.new(:file_pattern_tool, :review, context: context)

      assert_nil command.run_summary
    end

    def test_context_provides_history_for_seed
      history = Reviewer.history
      history.set(:dynamic_seed_tool, :last_seed, 99_999)
      arguments = Arguments.new(%w[failed])
      context = default_context(arguments: arguments, history: history)

      command = Reviewer::Command.new(:dynamic_seed_tool, :review, context: context)
      assert_equal 99_999, command.seed
    ensure
      history.set(:dynamic_seed_tool, :last_seed, nil)
    end

  end
end
