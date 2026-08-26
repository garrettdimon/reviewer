# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Reviewer
  class SetupTest < Minitest::Test
    FIXTURES = Pathname('test/fixtures/projects')

    def test_shows_already_exists_when_config_present
      with_temp_config(existing: true) do
        out, _err = capture_subprocess_io { Setup.run(configuration: Reviewer.configuration) }
        assert_match(/already exists/i, out)
        assert_match(/rvw doctor/, out)
        assert_match(/rvw init/, out)
      end
    end

    def test_shows_no_tools_when_empty_project
      with_temp_config do |config_file|
        out, _err = capture_subprocess_io do
          Setup.run(configuration: Reviewer.configuration, project_dir: FIXTURES.join('empty_project'))
        end
        assert_match(/no supported tools detected/i, out)
        assert_match(%r{github\.com/garrettdimon/reviewer}, out)
        refute config_file.exist?
      end
    end

    def test_generates_config_when_tools_detected
      with_temp_config do |config_file|
        out, _err = capture_subprocess_io do
          Setup.run(configuration: Reviewer.configuration, project_dir: FIXTURES.join('ruby_project'))
        end
        assert_match(/created \.reviewer\.yml/i, out)
        assert_match(/detected tools/i, out)
        assert config_file.exist?

        parsed = YAML.safe_load(config_file.read)
        assert parsed.key?('rubocop')
      end
    end

    def test_success_output_shows_tool_names_and_reasons
      with_temp_config do
        out, _err = capture_subprocess_io do
          Setup.run(configuration: Reviewer.configuration, project_dir: FIXTURES.join('ruby_project'))
        end
        assert_match(/RuboCop/, out)
        assert_match(/Gemfile\.lock/, out)
        assert_match(/rvw/, out)
      end
    end

    def test_uses_yarn_for_javascript_tools_when_yarn_lockfile_is_present
      command = generated_review_command(FIXTURES.join('js_yarn_project'), 'eslint')

      assert_equal 'yarn eslint .', command
    end

    def test_uses_pnpm_for_javascript_tools_when_pnpm_lockfile_is_present
      command = generated_review_command(FIXTURES.join('js_pnpm_project'), 'eslint')

      assert_equal 'pnpm exec eslint .', command
    end

    def test_uses_npx_for_javascript_tools_without_a_supported_lockfile
      command = generated_review_command(FIXTURES.join('js_project'), 'eslint')

      assert_equal 'npx eslint .', command
    end

    private

    # Sets up a temporary config file, yields it, and restores configuration.
    # @param existing [Boolean] if true, writes content to the config file before yielding
    def with_temp_config(existing: false)
      Dir.mktmpdir do |dir|
        config_file = Pathname(dir).join('.reviewer.yml')
        config_file.write('existing: config') if existing

        with_swapped_config(config_file) { yield config_file }
      end
    end

    def generated_review_command(project_dir, tool)
      with_temp_config do |config_file|
        capture_subprocess_io do
          Setup.run(configuration: Reviewer.configuration, project_dir: project_dir)
        end

        return YAML.safe_load(config_file.read).fetch(tool).fetch('commands').fetch('review')
      end
    end
  end
end
