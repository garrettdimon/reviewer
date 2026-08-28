# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

# rubocop:disable Metrics/BlockLength
namespace :release do
  desc 'Run bundle-audit to check for vulnerable dependencies'
  task :audit do
    puts 'Running security audit...'
    sh 'bundle exec bundle-audit check --update'
  end

  desc 'Validate version, changelog, and git state before release'
  task :check do
    require_relative 'lib/reviewer/version'
    errors = ReleaseChecker.new(Reviewer::VERSION).validate
    if errors.any?
      puts "\nRelease check failed:"
      errors.each { |e| puts "  - #{e}" }
      exit 1
    else
      puts 'All release checks passed.'
    end
  end

  desc 'Run all pre-release checks (tests, audit, release:check)'
  task preflight: %i[test audit check] do
    puts "\nAll preflight checks passed. Ready to release."
  end

  desc 'Build gem locally and show contents (dry run)'
  task :dry_run do
    require_relative 'lib/reviewer/version'
    DryRun.new(Reviewer::VERSION).run
  end
end
# rubocop:enable Metrics/BlockLength

# Validates release readiness
class ReleaseChecker
  def initialize(version)
    @version = version
    @errors = []
  end

  def validate
    puts "Checking release readiness for v#{@version}..."
    check_version_format
    check_changelog
    check_git_clean
    check_main_branch
    check_synced_with_origin
    @errors
  end

  private

  def check_version_format
    return if @version.match?(/\A\d+\.\d+\.\d+\z/)

    @errors << "Version '#{@version}' is not valid semver (expected X.Y.Z)"
  end

  def check_changelog
    changelog = File.read('CHANGELOG.md')
    unless changelog.match?(/^## \[#{Regexp.escape(@version)}\] - \d{4}-\d{2}-\d{2}$/)
      @errors << "CHANGELOG.md has no dated entry for version #{@version}"
      return
    end

    return unless release_notes(changelog).empty?

    # An empty section publishes a GitHub Release with a blank body, which
    # cannot be corrected without moving a tag RubyGems has already accepted
    @errors << "CHANGELOG.md has an empty section for version #{@version}"
  end

  # The lines the release workflow extracts for the GitHub Release body
  def release_notes(changelog)
    changelog[/^## \[#{Regexp.escape(@version)}\][^\n]*\n(.*?)(?=^## \[|\z)/m, 1].to_s.strip
  end

  # check_main_branch only compares the branch name, so a stale or ahead local
  # main passes it while pointing at a commit CI never saw
  def check_synced_with_origin
    return if `git rev-parse HEAD`.strip == `git rev-parse origin/main`.strip

    @errors << 'HEAD does not match origin/main'
  end

  def check_git_clean
    return if `git status --porcelain`.empty?

    @errors << 'Working directory has uncommitted changes'
  end

  def check_main_branch
    current_branch = `git branch --show-current`.strip
    return if current_branch == 'main'

    @errors << "Not on main branch (currently on '#{current_branch}')"
  end
end

# Builds gem and displays contents without publishing
class DryRun
  def initialize(version)
    @version = version
    @gem_file = "reviewer-#{version}.gem"
  end

  def run
    require "tmpdir"

    Dir.mktmpdir("reviewer-dry-run") do |directory|
      @gem_path = File.join(directory, @gem_file)
      build || abort('Gem build failed')
      show_contents
      show_size
    ensure
      cleanup if @gem_path && File.exist?(@gem_path)
    end
  end

  private

  def build
    puts "Building #{@gem_file}..."
    system 'gem', 'build', 'reviewer.gemspec', '--silent', '--output', @gem_path
  end

  def show_contents
    require "rubygems/package"

    puts "\nGem contents:"
    Gem::Package.new(@gem_path).contents.each { |path| puts path }
  end

  def show_size
    size = File.size(@gem_path)
    puts "\nGem size: #{(size / 1024.0).round(1)} KB"
  end

  def cleanup
    File.delete(@gem_path)
    puts "Cleaned up #{@gem_file}"
  end
end
