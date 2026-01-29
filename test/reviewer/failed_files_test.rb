# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class FailedFilesTest < Minitest::Test
    def test_extracts_rubocop_style_paths
      stdout = "lib/reviewer/batch.rb:45:3: C: Style/StringLiterals: Prefer double-quoted strings\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_includes files, 'lib/reviewer/batch.rb'
    end

    def test_extracts_minitest_style_paths
      stdout = "test/reviewer/batch_test.rb:45\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_includes files, 'test/reviewer/batch_test.rb'
    end

    def test_extracts_reek_style_paths
      stdout = "lib/reviewer/batch.rb -- SomeSmell: message\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_includes files, 'lib/reviewer/batch.rb'
    end

    def test_returns_empty_for_no_file_paths
      stdout = "Everything looks good!\nNo issues found.\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_empty files
    end

    def test_extracts_non_ruby_file_paths
      stdout = "reviewer.gemspec:3:1: C: Style/FrozenStringLiteral\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_includes files, 'reviewer.gemspec'
    end

    def test_extracts_indented_output
      stdout = "  lib/reviewer/batch.rb:10:3: C: Style/StringLiterals\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_includes files, 'lib/reviewer/batch.rb'
    end

    def test_filters_out_nonexistent_paths
      stdout = "totally/fake/path.rb:45:3: C: Style/StringLiterals\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_empty files
    end

    def test_deduplicates_results
      stdout = <<~OUTPUT
        lib/reviewer/batch.rb:10:3: C: Style/One
        lib/reviewer/batch.rb:20:5: C: Style/Two
      OUTPUT

      files = FailedFiles.new(stdout, nil).to_a

      assert_equal 1, files.count('lib/reviewer/batch.rb')
    end

    def test_handles_nil_stdout
      files = FailedFiles.new(nil, nil).to_a

      assert_empty files
    end

    def test_handles_nil_stderr
      stdout = "lib/reviewer/batch.rb:45:3: C: Style/StringLiterals\n"

      files = FailedFiles.new(stdout, nil).to_a

      assert_includes files, 'lib/reviewer/batch.rb'
    end

    def test_extracts_from_stderr
      stderr = "lib/reviewer/batch.rb:45:3: C: Style/StringLiterals\n"

      files = FailedFiles.new(nil, stderr).to_a

      assert_includes files, 'lib/reviewer/batch.rb'
    end

    def test_combines_stdout_and_stderr
      stdout = "lib/reviewer/batch.rb:10:3: C: Style/One\n"
      stderr = "lib/reviewer/command.rb:5:1: W: Warning\n"

      files = FailedFiles.new(stdout, stderr).to_a

      assert_includes files, 'lib/reviewer/batch.rb'
      assert_includes files, 'lib/reviewer/command.rb'
    end
  end
end
