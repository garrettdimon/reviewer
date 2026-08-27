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
end
