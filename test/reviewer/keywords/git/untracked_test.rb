# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Keywords
    module Git
      class UntrackedTest < Minitest::Test
        ProcessStatus = Struct.new(:success) do
          def success? = success
          def exitstatus = success? ? 0 : 99
        end

        def test_lists_untracked_files
          assert Untracked.list.is_a?(Array)
        end

        def test_parses_empty_output
          Open3.stub :capture3, ['', nil, ProcessStatus.new(true)] do
            assert_equal [], Untracked.list
          end
        end

        def test_parses_file_list
          output = "new_file.rb\ntemp/scratch.rb\n"

          Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
            assert_equal %w[new_file.rb temp/scratch.rb], Untracked.list
          end
        end

        def test_raises_on_git_failure
          assert_raises(SystemCallError) do
            Open3.stub :capture3, [nil, 'Error', ProcessStatus.new(false)] do
              Untracked.list
            end
          end
        end
      end
    end
  end
end
