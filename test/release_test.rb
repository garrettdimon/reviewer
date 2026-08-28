# frozen_string_literal: true

require 'test_helper'
require 'open3'

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
end
