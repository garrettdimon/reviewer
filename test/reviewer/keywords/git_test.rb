# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Keywords
    class GitTest < Minitest::Test
      # Stub for Open3 calls
      ProcessStatus = Struct.new(:success) do
        def success? = success
        def exitstatus = success? ? 0 : 99
      end

      def test_staged_command
        output = "lib/reviewer.rb\nlib/reviewer/output.rb\n"

        Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
          assert_equal %w[lib/reviewer.rb lib/reviewer/output.rb], Git.staged
        end
      end

      def test_unstaged_command
        output = "lib/changed.rb\n"

        Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
          assert_equal %w[lib/changed.rb], Git.unstaged
        end
      end

      def test_modified_command
        output = "lib/foo.rb\nlib/bar.rb\n"

        Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
          assert_equal %w[lib/foo.rb lib/bar.rb], Git.modified
        end
      end

      def test_untracked_command
        output = "new_file.rb\n"

        Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
          assert_equal %w[new_file.rb], Git.untracked
        end
      end

      def test_returns_empty_array_for_no_files
        Open3.stub :capture3, ['', nil, ProcessStatus.new(true)] do
          assert_equal [], Git.staged
        end
      end

      def test_raises_on_git_failure
        assert_raises(SystemCallError) do
          Open3.stub :capture3, [nil, 'Error', ProcessStatus.new(false)] do
            Git.staged
          end
        end
      end
    end
  end
end
