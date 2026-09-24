# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class FilesTest < Minitest::Test
      def test_array_casting
        assert_equal [], Files.new.to_a
        assert_equal ['*.css', '*.rb'], Files.new(provided: ['*.rb', '*.css'], keywords: []).to_a
      end

      def test_string_casting
        assert_equal '', Files.new.to_s
        assert_equal '*.css,*.rb', Files.new(provided: ['*.rb', '*.css'], keywords: []).to_s
      end

      def test_accepts_output_parameter
        output = Output.new
        files = Files.new(provided: [], keywords: [], output: output)
        assert_equal [], files.to_a
      end

      def test_raw_aliases_provided
        files = Files.new
        assert_equal files.provided, files.raw
      end

      def test_generating_files_from_flags
        files_array = ['*.css', '*.rb']
        files = Files.new(
          provided: files_array,
          keywords: []
        )

        assert_equal files_array.sort, files.to_a
      end

      def test_casting_to_hash
        files = Files.new
        assert files.to_h.key?(:provided)
        assert files.to_h.key?(:from_keywords)
      end

      def test_skips_generating_files_from_keywords_if_the_keyword_is_not_a_defined_method
        keywords_array = %w[not_a_real_keyword]
        files = Files.new(
          provided: [],
          keywords: keywords_array
        )

        assert_empty files.to_h[:from_keywords]
      end

      def test_generating_files_from_keywords
        staged_files = ['lib/reviewer.rb']
        keywords_array = %w[staged]
        files = Files.new(
          provided: [],
          keywords: keywords_array
        )

        stub_git_success("lib/reviewer.rb\n") do
          assert_equal staged_files, files.to_a
        end
      end

      def test_git_keywords_preserve_deleted_paths
        commands = {
          staged: 'git -c core.quotePath=false --no-pager diff --staged --name-only',
          unstaged: 'git -c core.quotePath=false --no-pager diff --name-only',
          modified: 'git -c core.quotePath=false --no-pager diff --name-only HEAD'
        }

        commands.each do |keyword, expected_command|
          command = nil
          git = lambda do |value|
            command = value
            ["deleted.rb\nkept.rb\n", '', MockStatus.new(true, 0)]
          end

          Open3.stub(:capture3, git) do
            assert_equal ['deleted.rb', 'kept.rb'], Files.new(keywords: [keyword]).to_a
          end
          assert_equal expected_command, command
        end
      end

      # Git escapes non-ASCII paths by default ("caf\303\251.rb"), and a non-UTF-8 locale labels its
      # output US-ASCII. Either way the real file would never be reviewed, so run against real git.
      def test_git_keywords_return_non_ascii_paths_as_utf8
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            system('git', 'init', '--quiet', exception: true)
            system('git', 'config', 'core.quotePath', 'true', exception: true)
            FileUtils.touch("caf\u00E9.rb")
            system('git', 'add', "caf\u00E9.rb", exception: true)

            files = with_default_external(Encoding::US_ASCII) { Files.new(keywords: %w[staged]).to_a }

            assert_equal ["caf\u00E9.rb"], files
          end
        end
      end

      def test_branched_selects_every_file_that_differs_from_origin_head
        with_repository_cloned_from_remote do
          diverge_feature_from_main
          File.write('staged.rb', "staged\n")
          git('add', 'staged.rb')
          File.write('base.rb', "edited\n")
          File.write('untracked.rb', "untracked\n")

          files = Files.new(keywords: %w[branched])

          assert_equal %w[base.rb committed.rb staged.rb untracked.rb], files.to_a
          assert_nil files.missing_base
        end
      end

      def test_branched_requires_origin_head_without_falling_back_to_main
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            git('init', '--quiet', '-b', 'main')
            commit('base.rb')
            git('remote', 'add', 'origin', File.join(dir, 'missing.git'))
            File.write('untracked.rb', "untracked\n")

            files = Files.new(keywords: %w[branched])

            assert_empty files.to_a
            assert_equal :origin_head, files.missing_base.reason
          end
        end
      end

      def test_branched_reports_other_git_errors_with_gits_message
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            missing = Files.new(keywords: %w[branched]).missing_base

            assert_equal :git_error, missing.reason
            assert_match(/not a git repository/, missing.detail)
          end
        end
      end

      def test_branched_reports_a_missing_merge_base_in_a_shallow_clone
        with_repository_cloned_from_remote do |remote|
          diverge_feature_from_main
          shallow = File.expand_path('../shallow', Dir.pwd)
          git('clone', '--quiet', '--depth', '1', '--no-single-branch', "file://#{remote}", shallow)
          Dir.chdir(shallow) do
            git('switch', '--quiet', 'feature')
            files = Files.new(keywords: %w[branched])

            assert_empty files.to_a
            assert_equal :merge_base, files.missing_base.reason
          end
        end
      end

      def test_generating_files_from_flags_and_keywords
        staged_files = ['lib/reviewer.rb']
        files_array = ['*.css', '*.rb']
        full_files_array = staged_files + files_array

        keywords_array = %w[staged]
        files = Files.new(
          provided: files_array,
          keywords: keywords_array
        )

        stub_git_success("lib/reviewer.rb\n") do
          assert_equal full_files_array.sort, files.to_a
        end
      end

      def test_generating_files_from_unstaged_keyword
        files = Files.new(provided: [], keywords: %w[unstaged])

        stub_git_success("lib/reviewer.rb\n") do
          assert_equal ['lib/reviewer.rb'], files.to_a
        end
      end

      def test_generating_files_from_modified_keyword
        files = Files.new(provided: [], keywords: %w[modified])

        stub_git_success("lib/reviewer.rb\nlib/reviewer/output.rb\n") do
          assert_equal ['lib/reviewer.rb', 'lib/reviewer/output.rb'], files.to_a
        end
      end

      def test_generating_files_from_untracked_keyword
        files = Files.new(provided: [], keywords: %w[untracked])

        stub_git_success("new_file.rb\n") do
          assert_equal ['new_file.rb'], files.to_a
        end
      end

      def test_git_error_calls_callback_and_returns_empty
        errors = []
        files = Files.new(provided: [], keywords: %w[staged], on_git_error: ->(msg) { errors << msg })

        stub_git_failure('fatal: not a git repository', 128) do
          assert_empty files.to_a
          assert_equal 1, errors.size
          assert_match(/not a git repository/i, errors.first)
        end
      end

      def test_git_error_continues_with_provided_files
        errors = []
        files = Files.new(provided: ['app/models/user.rb'], keywords: %w[staged], on_git_error: ->(msg) { errors << msg })

        stub_git_failure('git error', 1) do
          assert_equal ['app/models/user.rb'], files.to_a
          assert_equal 1, errors.size
        end
      end

      def test_git_error_without_callback_returns_empty_silently
        files = Files.new(provided: [], keywords: %w[staged])

        stub_git_failure('fatal: not a git repository', 128) do
          assert_empty files.to_a
        end
      end

      MockStatus = Struct.new(:success?, :exitstatus)

      private

      # Seeds a bare remote whose default branch is main, then clones it so origin/HEAD is set.
      # Yields inside the clone with the remote's path.
      def with_repository_cloned_from_remote
        Dir.mktmpdir do |dir|
          seed = File.join(dir, 'seed')
          remote = File.join(dir, 'remote.git')
          git('init', '--quiet', '-b', 'main', seed)
          Dir.chdir(seed) { commit('base.rb') }
          git('clone', '--quiet', '--bare', seed, remote)
          git('clone', '--quiet', remote, File.join(dir, 'clone'))
          Dir.chdir(File.join(dir, 'clone')) { yield remote }
        end
      end

      # Commits committed.rb on a new `feature` branch, then advances main past the branch point.
      # Both branches are pushed, and `feature` is left checked out.
      def diverge_feature_from_main
        git('switch', '--quiet', '-c', 'feature')
        commit('committed.rb')
        git('push', '--quiet', 'origin', 'feature')
        git('switch', '--quiet', 'main')
        commit('later_on_main.rb')
        git('push', '--quiet', 'origin', 'main')
        git('switch', '--quiet', 'feature')
      end

      def commit(file)
        File.write(file, "#{file}\n")
        git('add', file)
        git('-c', 'user.name=Reviewer Test', '-c', 'user.email=reviewer@example.com',
            'commit', '--quiet', '-m', file)
      end

      def git(*)
        system('git', *, exception: true, out: File::NULL, err: File::NULL)
      end

      def stub_git_success(stdout, &)
        Open3.stub(:capture3, [stdout, '', MockStatus.new(true, 0)], &)
      end

      def stub_git_failure(stderr, exit_code, &)
        Open3.stub(:capture3, ['', stderr, MockStatus.new(false, exit_code)], &)
      end
    end
  end
end
