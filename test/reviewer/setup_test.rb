# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Reviewer
  class SetupTest < Minitest::Test
    FIXTURES = Pathname('test/fixtures/projects')

    def test_shows_already_exists_when_config_present
      with_temp_config(existing: true) do
        out, _err = capture_subprocess_io { Setup.run }
        assert_match(/already exists/i, out)
        assert_match(/rvw doctor/, out)
        assert_match(/rvw init/, out)
      end
    end

    def test_shows_no_tools_when_empty_project
      with_temp_config do |config_file|
        out, _err = capture_subprocess_io do
          Setup.run(project_dir: FIXTURES.join('empty_project'))
        end
        assert_match(/no supported tools detected/i, out)
        assert_match(%r{github\.com/garrettdimon/reviewer}, out)
        refute config_file.exist?
      end
    end

    def test_generates_config_when_tools_detected
      with_temp_config do |config_file|
        out, _err = capture_subprocess_io do
          Setup.run(project_dir: FIXTURES.join('ruby_project'))
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
          Setup.run(project_dir: FIXTURES.join('ruby_project'))
        end
        assert_match(/RuboCop/, out)
        assert_match(/Gemfile\.lock/, out)
        assert_match(/rvw/, out)
      end
    end

    private

    # Sets up a temporary config file, yields it, and restores test configuration.
    # @param existing [Boolean] if true, writes content to the config file before yielding
    def with_temp_config(existing: false)
      Dir.mktmpdir do |dir|
        config_file = Pathname(dir).join('.reviewer.yml')
        config_file.write('existing: config') if existing

        Reviewer.configure { |c| c.file = config_file }
        yield config_file
      ensure
        ensure_test_configuration!
      end
    end
  end
end
