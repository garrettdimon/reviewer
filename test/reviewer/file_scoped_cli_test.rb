# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'tmpdir'

module Reviewer
  class FileScopedCLITest < Minitest::Test
    FIXTURES = Pathname('test/fixtures/files').expand_path
    EXECUTABLE = Pathname('exe/rvw').expand_path

    def test_cli_preserves_file_scope_across_every_selector
      Dir.mktmpdir do |directory|
        prepare_project(directory)

        assert_selector_matrix(directory)
        assert_retry_matrix(directory)
        assert_human_skip(directory)
        assert_empty_scope_matrix(directory)
      end
    end

    private

    def prepare_project(directory)
      copy_project_fixtures(directory)
      initialize_repository(directory)
      create_file_states(directory)
    end

    def copy_project_fixtures(directory)
      FileUtils.cp(FIXTURES.join('file_scoped_cli.yml'), File.join(directory, '.reviewer.yml'))
      FileUtils.cp(FIXTURES.join('file_scoped_cli.gitignore'), File.join(directory, '.gitignore'))
      FileUtils.cp(FIXTURES.join('record_invocation.rb'), directory)
      %w[staged_only.rb unstaged_only.rb both.rb].each { |file| FileUtils.touch(File.join(directory, file)) }
    end

    def initialize_repository(directory)
      git(directory, 'init', '--quiet')
      git(directory, 'config', 'user.email', 'reviewer@example.com')
      git(directory, 'config', 'user.name', 'Reviewer Test')
      git(directory, 'add', '.')
      git(directory, 'commit', '--quiet', '-m', 'fixture')
    end

    def create_file_states(directory)
      File.write(File.join(directory, 'staged_only.rb'), "staged\n")
      File.write(File.join(directory, 'both.rb'), "staged\n")
      git(directory, 'add', 'staged_only.rb', 'both.rb')
      File.write(File.join(directory, 'unstaged_only.rb'), "unstaged\n")
      File.write(File.join(directory, 'both.rb'), "staged\nunstaged\n")
      File.write(File.join(directory, 'untracked.rb'), "untracked\n")
    end

    def assert_selector_matrix(directory)
      assert_run(directory, [], expected: [invocation('broad'), invocation('file_aware')])
      assert_run(directory, %w[-f staged_only.rb -f untracked.rb],
                 expected: [invocation('file_aware', 'staged_only.rb', 'untracked.rb')], skipped: 1)
      assert_git_selectors(directory)
      assert_run(directory, %w[broad -f staged_only.rb], expected: [], skipped: 1)
    end

    def assert_git_selectors(directory)
      cases = {
        %w[staged] => %w[both.rb staged_only.rb],
        %w[unstaged] => %w[both.rb unstaged_only.rb],
        %w[modified] => %w[both.rb staged_only.rb unstaged_only.rb],
        %w[untracked] => %w[untracked.rb],
        %w[staged untracked] => %w[both.rb staged_only.rb untracked.rb]
      }

      cases.each do |arguments, files|
        assert_run(directory, arguments, expected: [invocation('file_aware', *files)], skipped: 1)
      end
    end

    def assert_retry_matrix(directory)
      assert_failed_retries(directory)
      assert_failed_retry_without_stored_paths(directory)
    end

    def assert_empty_scope_matrix(directory)
      assert_usage_error(directory, %w[-f])
      assert_usage_error(directory, ['-f', ''])
      commit_changes(directory)
      assert_empty_git_scope(directory)
    end

    def assert_run(directory, arguments, expected:, skipped: 0)
      stdout, stderr, status = run_cli(directory, *arguments, '--json')
      payload = JSON.parse(stdout)

      assert status.success?, stderr
      assert_equal expected, invocations(directory)
      assert_equal skipped, payload.dig('summary', 'skipped')
      assert payload['success']
      assert_skipped_results(payload, skipped)
    ensure
      FileUtils.rm_f(log_path(directory))
    end

    def assert_failed_retries(directory)
      seed_failures(directory)
      assert_run(directory, %w[failed -f unstaged_only.rb],
                 expected: [invocation('file_aware', 'unstaged_only.rb')], skipped: 1)

      seed_failures(directory)
      assert_run(directory, %w[failed],
                 expected: [invocation('broad'), invocation('file_aware', 'staged_only.rb')])
    end

    def assert_failed_retry_without_stored_paths(directory)
      _stdout, _stderr, status = run_cli(directory, 'file_aware', '--json',
                                         environment: { 'FAILING_TOOL' => 'file_aware' })
      assert_equal 1, status.exitstatus
      FileUtils.rm_f(log_path(directory))

      assert_run(directory, %w[failed], expected: [invocation('file_aware')])
    end

    def seed_failures(directory)
      _stdout, _stderr, broad_status = run_cli(directory, 'broad', '--json',
                                               environment: { 'FAILING_TOOL' => 'broad' })
      assert_equal 1, broad_status.exitstatus
      FileUtils.rm_f(log_path(directory))

      _stdout, _stderr, file_status = run_cli(
        directory,
        'file_aware', '-f', 'staged_only.rb', '--json',
        environment: { 'FAILING_TOOL' => 'file_aware', 'FAILED_PATH' => 'staged_only.rb' }
      )
      assert_equal 1, file_status.exitstatus
      FileUtils.rm_f(log_path(directory))
    end

    def assert_human_skip(directory)
      stdout, stderr, status = run_cli(directory, '-f', 'staged_only.rb')

      assert status.success?, stderr
      assert_match(/Broad/, stdout)
      assert_match(/Skipped \(no matching files\)/, stdout)
      assert_equal [invocation('file_aware', 'staged_only.rb')], invocations(directory)
    ensure
      FileUtils.rm_f(log_path(directory))
    end

    def commit_changes(directory)
      git(directory, 'add', 'staged_only.rb', 'unstaged_only.rb', 'both.rb', 'untracked.rb')
      git(directory, 'commit', '--quiet', '-m', 'clean fixture')
    end

    def assert_empty_git_scope(directory)
      stdout, stderr, status = run_cli(directory, 'staged', '--json')
      payload = JSON.parse(stdout)

      assert status.success?, stderr
      assert_equal 'empty', payload['state']
      assert_equal 'No reviewable staged files found', payload['message']
      assert_empty invocations(directory)
    ensure
      FileUtils.rm_f(log_path(directory))
    end

    def assert_skipped_results(payload, expected_count)
      skipped = payload.fetch('tools').select { |tool| tool['state'] == 'skipped' }

      assert_equal expected_count, skipped.size
      skipped.each do |tool|
        refute tool['success']
        assert_nil tool['exit_status']
        assert_nil tool['duration']
        assert_nil tool['stdout']
        assert_nil tool['stderr']
      end
    end

    def assert_usage_error(directory, arguments)
      stdout, _stderr, status = run_cli(directory, *arguments, '--json')
      payload = JSON.parse(stdout)

      assert_equal Session::USAGE_ERROR, status.exitstatus
      assert_equal 'error', payload['state']
      assert_equal 'missing_files', payload.dig('error', 'code')
      assert_empty invocations(directory)
    ensure
      FileUtils.rm_f(log_path(directory))
    end

    def run_cli(directory, *, environment: {})
      Open3.capture3(
        { 'INVOCATION_LOG' => log_path(directory) }.merge(environment),
        RbConfig.ruby,
        EXECUTABLE.to_s,
        *,
        chdir: directory
      )
    end

    def invocations(directory)
      return [] unless File.exist?(log_path(directory))

      File.readlines(log_path(directory), chomp: true).map { |line| JSON.parse(line) }
    end

    def invocation(tool, *arguments) = { 'tool' => tool, 'argv' => arguments }
    def log_path(directory) = File.join(directory, 'invocations.jsonl')

    def git(directory, *)
      system('git', *, chdir: directory, exception: true)
    end
  end
end
