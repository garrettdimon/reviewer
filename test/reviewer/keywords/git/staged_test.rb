# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Keywords
    module Git
      # For stubbing Open3 calls.
      ProcessStatus = Struct.new(:success) do
        def success?
          success
        end

        def exitstatus
          success? ? 0 : 99
        end
      end

      class StagedTest < Minitest::Test
        def test_lists_staged_files_via_class_method
          assert_equal Staged.new.list, Staged.list
        end

        def test_lists_staged_files
          assert Staged.list.is_a?(Array)
        end

        def test_parses_empty_git_command_output
          # rubocop:disable Style/EmptyHeredoc
          empty_staged_files_list = <<~EMPTY_GIT_OUTPUT
          EMPTY_GIT_OUTPUT
          # rubocop:enable Style/EmptyHeredoc

          # Instead of staging files, stub the Open3 call.
          Open3.stub :capture3, [empty_staged_files_list, nil, ProcessStatus.new(true)] do
            assert_equal [], Staged.list
          end
        end

        def test_parses_git_command_output
          staged_files_list = <<~GIT_OUTPUT
            lib/reviewer.rb
            lib/reviewer/arguments/files.rb
            lib/reviewer/arguments/keywords.rb
            lib/reviewer/arguments/tags.rb
          GIT_OUTPUT

          # Instead of staging files, stub the Open3 call.
          Open3.stub :capture3, [staged_files_list, nil, ProcessStatus.new(true)] do
            assert_equal staged_files_list.split("\n"), Staged.list
          end
        end

        def test_raises_exception_on_git_failure
          assert_raises(SystemCallError) do
            # Instead of staging files, stub the Open3 call.
            Open3.stub :capture3, [nil, 'Error', ProcessStatus.new(false)] do
              Staged.new.list
            end
          end
        end
      end
    end
  end
end
