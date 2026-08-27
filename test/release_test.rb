# frozen_string_literal: true

require 'test_helper'
require 'open3'

class ReleaseTest < Minitest::Test
  def test_dry_run_lists_the_packaged_files
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'release:dry_run')

    assert status.success?, stderr
    %w[exe/rvw exe/fmt lib/reviewer.rb README.md LICENSE.txt reviewer.gemspec].each do |path|
      assert_includes stdout, path
    end
  end

  def test_dry_run_preserves_an_existing_gem
    gem_file = "reviewer-#{Reviewer::VERSION}.gem"
    File.write(gem_file, 'existing artifact')

    _stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rake', 'release:dry_run')

    assert status.success?, stderr
    assert File.exist?(gem_file), "#{gem_file} was deleted"
    assert_equal 'existing artifact', File.read(gem_file)
  ensure
    File.delete(gem_file) if gem_file && File.exist?(gem_file)
  end
end
