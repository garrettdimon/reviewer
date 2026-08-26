# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Doctor
    class DiscoveryCheckTest < Minitest::Test
      FIXTURES = Pathname('test/fixtures/projects')

      def test_groups_direct_commands_by_tool
        report = Report.new
        DiscoveryCheck.new(report, FIXTURES.join('js_project'), configured_keys: []).check

        eslint = report.discoveries.find { |discovery| discovery.key == :eslint }
        assert_equal 'ESLint', eslint.name
        assert_includes eslint.observations.map(&:to_h), {
          kind: :command,
          value: 'eslint .',
          source: { path: 'package.json', location: 'scripts.lint' }
        }
      end

      def test_groups_filesystem_sources_by_tool
        eslint = run_check(FIXTURES.join('js_project')).discoveries.find do |discovery|
          discovery.key == :eslint
        end

        assert_includes eslint.observations.map(&:to_h), {
          kind: :configuration_file,
          source: { path: '.eslintrc.json' }
        }
      end

      def test_ignores_compound_multiline_delegated_and_environment_prefixed_scripts
        report = run_check(FIXTURES.join('js_project'))
        commands = report.discoveries.flat_map(&:observations).filter_map do |observation|
          observation.value if observation.kind == :command
        end

        assert_equal ['eslint .', 'prettier --check .', 'tsc --noEmit'], commands
      end

      def test_excludes_configured_tools
        report = run_check(FIXTURES.join('js_project'), configured_keys: [:eslint])

        refute_includes report.discoveries.map(&:key), :eslint
        assert_includes report.discoveries.map(&:key), :prettier
      end

      def test_retains_filesystem_discoveries_when_package_json_is_invalid
        report = run_check(FIXTURES.join('invalid_package_project'))
        eslint = report.discoveries.find { |discovery| discovery.key == :eslint }

        assert_equal [{ kind: :configuration_file, source: { path: 'eslint.config.js' } }],
                     eslint.observations.map(&:to_h)
      end

      def test_retains_filesystem_discoveries_when_package_scripts_are_not_a_mapping
        report = run_check(FIXTURES.join('invalid_package_shape_project'))
        eslint = report.discoveries.find { |discovery| discovery.key == :eslint }

        assert_equal [{ kind: :configuration_file, source: { path: 'eslint.config.js' } }],
                     eslint.observations.map(&:to_h)
      end

      private

      def run_check(project_dir, configured_keys: [])
        report = Report.new
        DiscoveryCheck.new(report, project_dir, configured_keys: configured_keys).check
        report
      end
    end
  end
end
