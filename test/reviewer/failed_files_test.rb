# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class FailedFilesTest < Minitest::Test
    def test_matches_rubocop_style_paths
      stdout = "lib/reviewer/batch.rb:45:3: C: Style/StringLiterals: Prefer double-quoted strings\n"

      assert_includes FailedFiles.new(stdout, nil).matched_paths, 'lib/reviewer/batch.rb'
    end

    def test_matches_minitest_style_paths
      stdout = "test/reviewer/batch_test.rb:45\n"

      assert_includes FailedFiles.new(stdout, nil).matched_paths, 'test/reviewer/batch_test.rb'
    end

    def test_matches_reek_style_paths
      stdout = "lib/reviewer/batch.rb -- SomeSmell: message\n"

      assert_includes FailedFiles.new(stdout, nil).matched_paths, 'lib/reviewer/batch.rb'
    end

    def test_matches_non_ruby_file_extensions
      stdout = "src/app.js:10:5: error Missing semicolon\n"

      assert_includes FailedFiles.new(stdout, nil).matched_paths, 'src/app.js'
    end

    def test_matches_indented_output
      stdout = "  lib/reviewer/batch.rb:10:3: C: Style/StringLiterals\n"

      assert_includes FailedFiles.new(stdout, nil).matched_paths, 'lib/reviewer/batch.rb'
    end

    def test_returns_empty_for_no_file_paths
      stdout = "Everything looks good!\nNo issues found.\n"

      assert_empty FailedFiles.new(stdout, nil).matched_paths
    end

    def test_matches_from_stderr
      stderr = "lib/reviewer/batch.rb:45:3: C: Style/StringLiterals\n"

      assert_includes FailedFiles.new(nil, stderr).matched_paths, 'lib/reviewer/batch.rb'
    end

    def test_matches_from_both_stdout_and_stderr
      stdout = "lib/reviewer/batch.rb:10:3: C: Style/One\n"
      stderr = "lib/reviewer/command.rb:5:1: W: Warning\n"

      paths = FailedFiles.new(stdout, stderr).matched_paths

      assert_includes paths, 'lib/reviewer/batch.rb'
      assert_includes paths, 'lib/reviewer/command.rb'
    end

    def test_handles_nil_inputs
      assert_empty FailedFiles.new(nil, nil).matched_paths
    end

    def test_handles_empty_string_inputs
      assert_empty FailedFiles.new("", "").matched_paths
    end

    def test_filters_nonexistent_paths
      stdout = "totally/fake/path.rb:45:3: C: Style/StringLiterals\n"

      assert_includes FailedFiles.new(stdout, nil).matched_paths, 'totally/fake/path.rb'
      assert_empty FailedFiles.new(stdout, nil).to_a
    end

    def test_deduplicates_results
      stdout = <<~OUTPUT
        lib/reviewer/batch.rb:10:3: C: Style/One
        lib/reviewer/batch.rb:20:5: C: Style/Two
      OUTPUT

      assert_equal 1, FailedFiles.new(stdout, nil).to_a.count('lib/reviewer/batch.rb')
    end
  end
end
