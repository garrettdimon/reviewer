# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Setup
    class GemfileLockTest < Minitest::Test
      FIXTURES = Pathname('test/fixtures/projects')

      def test_parses_gem_names_from_specs_section
        lockfile = GemfileLock.new(FIXTURES.join('ruby_project/Gemfile.lock'))
        gems = lockfile.gem_names

        assert_includes gems, 'bundler-audit'
        assert_includes gems, 'minitest'
        assert_includes gems, 'rubocop'
        assert_includes gems, 'reek'
      end

      def test_includes_transitive_dependencies
        lockfile = GemfileLock.new(FIXTURES.join('ruby_project/Gemfile.lock'))
        gems = lockfile.gem_names

        assert_includes gems, 'ast'
      end

      def test_returns_empty_set_for_missing_file
        lockfile = GemfileLock.new(Pathname('nonexistent/Gemfile.lock'))
        assert_empty lockfile.gem_names
      end

      def test_returns_empty_set_for_empty_project
        lockfile = GemfileLock.new(FIXTURES.join('empty_project/Gemfile.lock'))
        assert_empty lockfile.gem_names
      end
    end
  end
end
