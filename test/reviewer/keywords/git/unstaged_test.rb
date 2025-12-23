# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Keywords
    module Git
      class UnstagedTest < Minitest::Test
        ProcessStatus = Struct.new(:success) do
          def success? = success
          def exitstatus = success? ? 0 : 99
        end

        def test_lists_unstaged_files
          assert Unstaged.list.is_a?(Array)
        end

        def test_parses_empty_output
          Open3.stub :capture3, ['', nil, ProcessStatus.new(true)] do
            assert_equal [], Unstaged.list
          end
        end

        def test_parses_file_list
          output = "lib/reviewer.rb\nlib/reviewer/output.rb\n"

          Open3.stub :capture3, [output, nil, ProcessStatus.new(true)] do
            assert_equal %w[lib/reviewer.rb lib/reviewer/output.rb], Unstaged.list
          end
        end

        def test_raises_on_git_failure
          assert_raises(SystemCallError) do
            Open3.stub :capture3, [nil, 'Error', ProcessStatus.new(false)] do
              Unstaged.list
            end
          end
        end
      end
    end
  end
end
