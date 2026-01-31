# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Setup
    class DetectorTest < Minitest::Test
      FIXTURES = Pathname('test/fixtures/projects')

      def test_detects_gems_from_gemfile_lock
        detector = Detector.new(FIXTURES.join('ruby_project'))
        results = detector.detect

        keys = results.map(&:key)
        assert_includes keys, :bundle_audit
        assert_includes keys, :rubocop
        assert_includes keys, :reek
        assert_includes keys, :tests
      end

      def test_detects_config_files
        detector = Detector.new(FIXTURES.join('ruby_project'))
        results = detector.detect

        rubocop = results.find { |r| r.key == :rubocop }
        assert_includes rubocop.reasons, '.rubocop.yml'
      end

      def test_detects_directories
        detector = Detector.new(FIXTURES.join('ruby_project'))
        results = detector.detect

        tests = results.find { |r| r.key == :tests }
        assert_includes tests.reasons, 'test/ directory'
      end

      def test_detects_rails_project_tools
        detector = Detector.new(FIXTURES.join('rails_project'))
        results = detector.detect

        keys = results.map(&:key)
        assert_includes keys, :brakeman
        assert_includes keys, :specs
        assert_includes keys, :rubocop
      end

      def test_brakeman_requires_controllers_directory
        # ruby_project has brakeman-less Gemfile.lock and no app/controllers
        detector = Detector.new(FIXTURES.join('ruby_project'))
        results = detector.detect

        keys = results.map(&:key)
        refute_includes keys, :brakeman
      end

      def test_returns_empty_for_empty_project
        detector = Detector.new(FIXTURES.join('empty_project'))
        results = detector.detect

        assert_empty results
      end

      def test_results_include_gem_reasons
        detector = Detector.new(FIXTURES.join('ruby_project'))
        results = detector.detect

        bundle_audit = results.find { |r| r.key == :bundle_audit }
        assert_includes bundle_audit.reasons, 'bundler-audit in Gemfile.lock'
      end

      def test_results_include_directory_reasons
        detector = Detector.new(FIXTURES.join('rails_project'))
        results = detector.detect

        brakeman = results.find { |r| r.key == :brakeman }
        assert_includes brakeman.reasons, 'app/controllers/ directory'
      end

      def test_handles_missing_gemfile_lock
        detector = Detector.new(FIXTURES.join('empty_project'))
        results = detector.detect

        assert_empty results
      end

      def test_detects_js_tools_from_config_files
        detector = Detector.new(FIXTURES.join('js_project'))
        results = detector.detect

        keys = results.map(&:key)
        assert_includes keys, :eslint
        assert_includes keys, :prettier
        assert_includes keys, :typescript
      end

      def test_js_detection_includes_file_reasons
        detector = Detector.new(FIXTURES.join('js_project'))
        results = detector.detect

        eslint = results.find { |r| r.key == :eslint }
        assert_includes eslint.reasons, '.eslintrc.json'
      end

      def test_combined_ruby_and_js_detection
        detector = Detector.new(FIXTURES.join('rails_with_js'))
        results = detector.detect

        keys = results.map(&:key)
        assert_includes keys, :rubocop
        assert_includes keys, :brakeman
        assert_includes keys, :eslint
        assert_includes keys, :prettier
      end
    end
  end
end
