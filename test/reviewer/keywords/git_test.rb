# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Keywords
    module Git
      # Stub for Open3 calls
      ProcessStatus = Struct.new(:success) do
        def success? = success
        def exitstatus = success? ? 0 : 99
      end

      class BaseTest < Minitest::Test
        def test_parses_empty_output
          Open3.stub :capture3, ['', nil, ProcessStatus.new(true)] do
            assert_equal [], Staged.list
          end
        end

        def test_parses_file_list
          output = "lib/reviewer.rb\nlib/reviewer/output.rb\n"

          Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
            assert_equal %w[lib/reviewer.rb lib/reviewer/output.rb], Staged.list
          end
        end

        def test_raises_on_git_failure
          assert_raises(SystemCallError) do
            Open3.stub :capture3, [nil, 'Error', ProcessStatus.new(false)] do
              Staged.list
            end
          end
        end
      end

      class StagedTest < Minitest::Test
        def test_command
          assert_equal 'git --no-pager diff --staged --name-only', Staged.new.command
        end
      end

      class UnstagedTest < Minitest::Test
        def test_command
          assert_equal 'git --no-pager diff --name-only', Unstaged.new.command
        end
      end

      class ModifiedTest < Minitest::Test
        def test_command
          assert_equal 'git --no-pager diff --name-only HEAD', Modified.new.command
        end
      end

      class UntrackedTest < Minitest::Test
        def test_command
          assert_equal 'git --no-pager ls-files --others --exclude-standard', Untracked.new.command
        end
      end
    end
  end
end
