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

      def test_git_error_returns_empty_and_warns
        files = Files.new(provided: [], keywords: %w[staged])

        stub_git_failure('fatal: not a git repository', 128) do
          out, _err = capture_subprocess_io { files.to_a }
          assert_empty files.to_a
          assert_match(/not a git repository/i, out)
        end
      end

      def test_git_error_continues_with_provided_files
        files = Files.new(provided: ['app/models/user.rb'], keywords: %w[staged])

        stub_git_failure('git error', 1) do
          capture_subprocess_io do
            assert_equal ['app/models/user.rb'], files.to_a
          end
        end
      end

      MockStatus = Struct.new(:success?, :exitstatus)

      private

      def stub_git_success(stdout, &)
        Open3.stub(:capture3, [stdout, '', MockStatus.new(true, 0)], &)
      end

      def stub_git_failure(stderr, exit_code, &)
        Open3.stub(:capture3, ['', stderr, MockStatus.new(false, exit_code)], &)
      end
    end
  end
end
