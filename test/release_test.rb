# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'yaml'
load File.expand_path('../Rakefile', __dir__)

class ReleaseTest < Minitest::Test
  def test_dry_run_lists_the_packaged_files
    %w[
      exe/rvw exe/fmt lib/reviewer.rb README.md CHANGELOG.md LICENSE.txt
      CODE_OF_CONDUCT.md docs/usage.md .reviewer.example.yml reviewer.gemspec
    ].each do |path|
      assert_includes packaged_paths, path
    end
  end

  def test_dry_run_excludes_development_files
    %w[
      structure.svg favicon.svg .reek.yml .rubocop.yml Gemfile Gemfile.lock
      Rakefile RELEASING.md AGENTS.md dependency_decisions.yml
      .github/workflows/release.yml bin/setup
    ].each do |path|
      refute_includes packaged_paths, path
    end
  end

  def test_release_check_reports_a_mismatch_exactly_when_head_differs
    origin_main = `git rev-parse --verify --quiet origin/main`.strip
    errors = release_check_errors

    # A checkout without origin/main is a different error, not a mismatch
    if origin_main.empty?
      assert_includes errors, 'Cannot resolve origin/main. Run `git fetch origin main`.'
    else
      synced = `git rev-parse HEAD`.strip == origin_main

      assert_equal !synced, errors.include?('HEAD does not match origin/main')
    end
  end

  def test_release_check_accepts_a_dated_changelog_section_with_notes
    refute_includes release_check_errors.join("\n"), 'CHANGELOG'
  end

  def test_release_tag_must_match_the_version
    checker = ReleaseChecker.new('1.1.1')

    assert_includes checker.validate_tag('v1.1.0'), "Tag 'v1.1.0' does not match version 1.1.1"
  end

  def test_release_notes_match_the_exact_version_heading
    changelog = <<~CHANGELOG
      ## [1x1x1] - 2026-09-01

      Wrong notes

      ## [1.1.1] - 2026-09-02

      Right notes
    CHANGELOG

    checker = ReleaseChecker.new('1.1.1', changelog: changelog)
    assert_equal 'Right notes', checker.release_notes
  end

  def test_release_notes_use_the_dated_heading_that_was_validated
    changelog = <<~CHANGELOG
      ## [1.1.1] draft

      Unvalidated notes

      ## [1.1.1] - 2026-09-02

      Validated notes
    CHANGELOG

    checker = ReleaseChecker.new('1.1.1', changelog: changelog)

    assert_empty checker.validate_tag('v1.1.1')
    assert_equal 'Validated notes', checker.release_notes
  end

  def test_release_tag_rejects_an_impossible_changelog_date
    changelog = <<~CHANGELOG
      ## [1.1.1] - 2026-99-99

      Invalid date
    CHANGELOG

    checker = ReleaseChecker.new('1.1.1', changelog: changelog)

    assert_includes checker.validate_tag('v1.1.1'), 'CHANGELOG.md has no dated entry for version 1.1.1'
    assert_empty checker.release_notes
  end

  def test_release_notes_task_prints_the_validated_notes
    stdout, stderr, status = Open3.capture3(
      { 'RELEASE_TAG' => "v#{Reviewer::VERSION}" },
      'bundle', 'exec', 'rake', 'release:notes'
    )

    assert status.success?, stderr
    assert_equal ReleaseChecker.new(Reviewer::VERSION).release_notes, stdout.strip
  end

  # GitHub Actions cannot run locally, so this protects the workflow's security boundary structurally.
  def test_release_workflow_pins_actions
    actions = release_workflow.fetch('jobs').values.flat_map do |job|
      job.fetch('steps').filter_map { |step| step['uses'] }
    end

    assert actions.all? { |action| action.match?(/\A[^@]+@[0-9a-f]{40}\z/) }, actions.inspect
  end

  # Action runtimes come from external metadata, so approved revisions are a structural contract.
  def test_workflows_use_supported_node_24_actions
    supported_revisions = {
      'actions/checkout' => '3d3c42e5aac5ba805825da76410c181273ba90b1', # v7.0.1
      'softprops/action-gh-release' => 'e598afbe1493e6b1bafb1f389cabb956eab91231' # v3.0.3
    }

    Dir['.github/workflows/*.yml'].each do |path|
      YAML.load_file(path).fetch('jobs').each_value do |job|
        job.fetch('steps').filter_map { |step| step['uses'] }.each do |action|
          name, revision = action.split('@', 2)
          next unless supported_revisions.key?(name)

          assert_equal supported_revisions.fetch(name), revision, "#{path} uses an unsupported #{name} revision"
        end
      end
    end
  end

  def test_release_workflow_limits_permissions
    workflow = release_workflow

    assert_equal({}, workflow.fetch('permissions'))
    assert_equal({ 'contents' => 'read' }, workflow.dig('jobs', 'validate', 'permissions'))
    assert_equal({ 'id-token' => 'write', 'contents' => 'read' }, workflow.dig('jobs', 'publish', 'permissions'))
    assert_equal({ 'contents' => 'write' }, workflow.dig('jobs', 'github-release', 'permissions'))
  end

  def test_release_workflow_does_not_interpolate_github_values_in_shell
    shell_commands = release_workflow.fetch('jobs').values.flat_map do |job|
      job.fetch('steps').filter_map { |step| step['run'] }
    end

    refute(shell_commands.any? { |command| command.include?('${{ github.') })
  end

  def test_dry_run_preserves_an_existing_gem
    gem_file = "reviewer-#{Reviewer::VERSION}.gem"
    existing_gem = File.binread(gem_file) if File.exist?(gem_file)
    File.write(gem_file, 'existing artifact')

    _stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'release:dry_run')

    assert status.success?, stderr
    assert File.exist?(gem_file), "#{gem_file} was deleted"
    assert_equal 'existing artifact', File.read(gem_file)
  ensure
    if existing_gem
      File.binwrite(gem_file, existing_gem)
    elsif gem_file && File.exist?(gem_file)
      File.delete(gem_file)
    end
  end

  private

  # Paths between the contents header and the size footer, so an incidental
  # mention elsewhere in the output cannot satisfy or defeat an assertion
  def release_check_errors
    @release_check_errors ||= begin
      stdout, stderr, _status = Open3.capture3('bundle', 'exec', 'rake', 'release:check')

      # Without this the task could die before reporting and every caller
      # would read the empty list as "no errors"
      assert_match(/Checking release readiness/, stdout, stderr)

      stdout.lines.map(&:chomp).filter_map { |line| line[/\A  - (.+)\z/, 1] }
    end
  end

  def packaged_paths
    @packaged_paths ||= begin
      stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'release:dry_run')
      assert status.success?, stderr
      listing = stdout[/Gem contents:\n(.*?)\nGem size:/m, 1]
      refute_nil listing, "release:dry_run printed no package listing:\n#{stdout}"
      listing.lines.map(&:chomp)
    end
  end

  def release_workflow
    @release_workflow ||= YAML.load_file('.github/workflows/release.yml')
  end
end
