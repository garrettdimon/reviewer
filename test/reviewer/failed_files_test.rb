# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class FailedFilesTest < Minitest::Test
    # --- Pattern matching: tool output formats ---

    def test_matches_rubocop_format
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "lib/reviewer/batch.rb:45:3: C: Style/StringLiterals: Prefer double-quoted strings\n"
    end

    def test_matches_minitest_format
      assert_match_extracts 'test/reviewer/batch_test.rb',
                            "test/reviewer/batch_test.rb:45\n"
    end

    def test_matches_reek_format
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "lib/reviewer/batch.rb -- SomeSmell: message\n"
    end

    def test_matches_eslint_format
      assert_match_extracts 'src/app.js',
                            "src/app.js:10:5: error Missing semicolon\n"
    end

    def test_matches_flay_format
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "lib/reviewer/batch.rb:10 (mass = 32)\n"
    end

    def test_matches_fasterer_format
      assert_match_extracts 'lib/reviewer/shell.rb',
                            "lib/reviewer/shell.rb:55 Array#sort + Array#first are slower than Enumerable#min_by.\n"
    end

    def test_matches_rubycritic_console_format
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "lib/reviewer/batch.rb -- Rating: A -- Score: 10.5\n"
    end

    def test_matches_grep_notes_format
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "lib/reviewer/batch.rb:45:# TODO: refactor this\n"
    end

    def test_matches_minitest_heat_format
      assert_match_extracts 'test/reviewer/batch_test.rb',
                            "test/reviewer/batch_test.rb:83 ➜ 83\n"
    end

    def test_matches_rspec_documentation_format
      assert_match_extracts './spec/models/user_spec.rb',
                            "     ./spec/models/user_spec.rb:15\n"
    end

    # --- Pattern matching: path variations ---

    def test_matches_deeply_nested_paths
      assert_match_extracts 'app/models/concerns/trackable.rb',
                            "app/models/concerns/trackable.rb:10:3: C: Style/Something\n"
    end

    def test_matches_single_digit_line_number
      assert_match_extracts 'lib/foo.rb',
                            "lib/foo.rb:1: C: Style/Something\n"
    end

    def test_matches_hyphenated_filename
      assert_match_extracts 'lib/some-file.rb',
                            "lib/some-file.rb:10:3: C: Style/Something\n"
    end

    def test_matches_underscored_filename
      assert_match_extracts 'lib/some_file.rb',
                            "lib/some_file.rb:10:3: C: Style/Something\n"
    end

    def test_matches_css_files
      assert_match_extracts 'app/assets/stylesheets/main.css',
                            "app/assets/stylesheets/main.css:5:1: warning some issue\n"
    end

    def test_matches_typescript_files
      assert_match_extracts 'src/components/App.tsx',
                            "src/components/App.tsx:10:5: error something\n"
    end

    # --- Pattern matching: whitespace handling ---

    def test_matches_indented_with_spaces
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "  lib/reviewer/batch.rb:10:3: C: Style/StringLiterals\n"
    end

    def test_matches_indented_with_tab
      assert_match_extracts 'lib/reviewer/batch.rb',
                            "\tlib/reviewer/batch.rb:10:3: C: Style/StringLiterals\n"
    end

    # --- Pattern matching: stream handling ---

    def test_matches_from_stderr
      assert_includes FailedFiles.new(nil, "lib/reviewer/batch.rb:45:3: C: Style/Something\n").matched_paths,
                      'lib/reviewer/batch.rb'
    end

    def test_matches_from_both_streams
      stdout = "lib/reviewer/batch.rb:10:3: C: Style/One\n"
      stderr = "lib/reviewer/command.rb:5:1: W: Warning\n"
      paths = FailedFiles.new(stdout, stderr).matched_paths

      assert_includes paths, 'lib/reviewer/batch.rb'
      assert_includes paths, 'lib/reviewer/command.rb'
    end

    # --- Pattern rejection: absolute paths ---

    def test_rejects_absolute_unix_paths
      assert_no_match_in "/home/user/project/lib/foo.rb:10:3: C: Style/Something\n"
    end

    def test_rejects_absolute_macos_paths
      assert_no_match_in "/Users/someone/code/lib/foo.rb:10:3: C: Style/Something\n"
    end

    def test_rejects_indented_absolute_paths
      assert_no_match_in "  /home/user/.rbenv/versions/3.4.5/lib/ruby/gems/3.4.0/gems/some-gem-1.0/lib/some_file.rb:64: warning: already initialized constant Foo::BAR\n"
    end

    def test_rejects_ruby_runtime_warnings
      stderr = <<~OUTPUT
        /home/user/.rbenv/versions/3.4.5/lib/ruby/gems/3.4.0/gems/some-gem-1.0/lib/some_file.rb:64: warning: already initialized constant Foo::BAR
        /home/user/.rbenv/versions/3.4.5/lib/ruby/site_ruby/3.4.0/rubygems/platform.rb:259: warning: previous definition of BAR was here
      OUTPUT

      assert_empty FailedFiles.new(nil, stderr).matched_paths
    end

    # --- Pattern rejection: non-path output ---

    def test_rejects_plain_text_messages
      assert_no_match_in "Everything looks good!\n"
    end

    def test_rejects_summary_lines
      assert_no_match_in "78 files inspected, 1 offense detected, 1 offense autocorrectable\n"
    end

    def test_rejects_progress_lines
      assert_no_match_in "Inspecting 78 files\n"
    end

    def test_rejects_progress_dots
      assert_no_match_in ".................C............................................................\n"
    end

    def test_rejects_blank_lines
      assert_no_match_in "\n"
    end

    def test_rejects_section_headers
      assert_no_match_in "Offenses:\n"
    end

    def test_rejects_files_without_extension
      assert_no_match_in "Gemfile:5: some issue\n"
    end

    def test_rejects_paths_without_line_or_separator
      assert_no_match_in "lib/reviewer/batch.rb is clean\n"
    end

    # --- Pattern rejection: tool-specific non-path output ---

    def test_rejects_flog_scores_with_midline_paths
      assert_no_match_in "     7.2: Reviewer::FailedFiles#combined_output lib/reviewer/failed_files.rb:54-56\n"
    end

    def test_rejects_bundle_audit_gem_names
      assert_no_match_in "Name: actionpack\n"
    end

    def test_rejects_bundle_audit_versions
      assert_no_match_in "Version: 5.0.0\n"
    end

    def test_rejects_brakeman_file_label_format
      assert_no_match_in "File: app/controllers/users_controller.rb\n"
    end

    def test_rejects_inch_midline_paths
      assert_no_match_in "┃  B  ↑  Reviewer::Batch#run    lib/reviewer/batch.rb:25\n"
    end

    # --- Filtering and deduplication ---

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

    # --- Pattern matching: ANSI color codes ---

    def test_matches_paths_wrapped_in_ansi_color_codes
      stdout = "\e[33mlib/reviewer/failed_files.rb\e[0m:23:25: C: [Correctable] Style/RegexpLiteral\n"

      assert_match_extracts 'lib/reviewer/failed_files.rb', stdout
    end

    def test_matches_paths_with_bold_ansi_codes
      stdout = "\e[1mlib/reviewer/batch.rb\e[0m:10:3: C: Style/Something\n"

      assert_match_extracts 'lib/reviewer/batch.rb', stdout
    end

    # --- Edge cases ---

    def test_handles_nil_inputs
      assert_empty FailedFiles.new(nil, nil).matched_paths
    end

    def test_handles_empty_string_inputs
      assert_empty FailedFiles.new('', '').matched_paths
    end

    private

    def assert_match_extracts(expected_path, output)
      assert_includes FailedFiles.new(output, nil).matched_paths, expected_path
    end

    def assert_no_match_in(output)
      assert_empty FailedFiles.new(output, nil).matched_paths
    end
  end
end
