# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Tool
    class FileResolverTest < Minitest::Test
      def test_returns_files_unchanged_when_no_pattern_configured
        settings = build_settings(files: nil)
        resolver = FileResolver.new(settings)

        result = resolver.resolve(['app/models/user.rb', 'lib/tool.rb'])

        assert_equal ['app/models/user.rb', 'lib/tool.rb'], result
      end

      def test_filters_files_by_pattern
        settings = build_settings(files: { pattern: '*.rb' })
        resolver = FileResolver.new(settings)

        result = resolver.resolve([
                                    'lib/reviewer/tool/file_resolver.rb',
                                    'README.md',
                                    'test/reviewer/tool/file_resolver_test.rb'
                                  ])

        assert_equal ['lib/reviewer/tool/file_resolver.rb',
                      'test/reviewer/tool/file_resolver_test.rb'], result
      end

      def test_omits_nonexistent_files_after_filtering
        settings = build_settings(files: { pattern: 'lib/**/*.rb' })
        resolver = FileResolver.new(settings)

        result = resolver.resolve(['lib/reviewer.rb', 'lib/deleted.rb'])

        assert_equal ['lib/reviewer.rb'], result
      end

      def test_matches_patterns_without_slashes_against_basename
        settings = build_settings(files: { pattern: 'reviewer*.rb' })
        resolver = FileResolver.new(settings)

        result = resolver.resolve(['lib/reviewer.rb', 'lib/tool.rb'])

        assert_equal ['lib/reviewer.rb'], result
      end

      def test_matches_patterns_with_slashes_against_repository_relative_paths
        settings = build_settings(files: { pattern: 'lib/**/*.rb' })
        resolver = FileResolver.new(settings)

        result = resolver.resolve([
                                    'lib/reviewer.rb',
                                    'lib/reviewer/tool/file_resolver.rb',
                                    'test/reviewer/tool/file_resolver_test.rb'
                                  ])

        assert_equal ['lib/reviewer.rb', 'lib/reviewer/tool/file_resolver.rb'], result
      end

      def test_matches_brace_alternatives_in_repository_relative_patterns
        settings = build_settings(files: { pattern: '{lib,test}/**/*.rb' })
        resolver = FileResolver.new(settings)

        result = resolver.resolve([
                                    'lib/reviewer.rb',
                                    'test/reviewer_test.rb',
                                    'exe/rvw'
                                  ])

        assert_equal ['lib/reviewer.rb', 'test/reviewer_test.rb'], result
      end

      def test_normalizes_dot_slash_for_matching_without_changing_the_result
        settings = build_settings(files: { pattern: 'lib/**/*.rb' })
        resolver = FileResolver.new(settings)

        result = resolver.resolve(['./lib/reviewer.rb'])

        assert_equal ['./lib/reviewer.rb'], result
      end

      def test_normalizes_repository_absolute_paths_without_changing_the_result
        settings = build_settings(files: { pattern: 'lib/**/*.rb' })
        resolver = FileResolver.new(settings)
        absolute_path = File.join(Dir.pwd, 'lib/reviewer.rb')

        result = resolver.resolve([absolute_path])

        assert_equal [absolute_path], result
      end

      def test_maps_source_files_to_test_files_when_configured
        settings = build_settings(files: { pattern: '*_test.rb', map_to_tests: 'minitest' })
        resolver = FileResolver.new(settings)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('test/models')
            FileUtils.touch('test/models/user_test.rb')

            result = resolver.resolve(['app/models/user.rb'])

            assert_equal ['test/models/user_test.rb'], result
          end
        end
      end

      def test_passes_through_test_files_unchanged_when_mapping_configured
        settings = build_settings(files: { pattern: '*_test.rb', map_to_tests: 'minitest' })
        resolver = FileResolver.new(settings)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('test/models')
            FileUtils.touch('test/models/user_test.rb')

            result = resolver.resolve(['test/models/user_test.rb'])

            assert_equal ['test/models/user_test.rb'], result
          end
        end
      end

      def test_returns_empty_when_mapped_test_does_not_exist
        settings = build_settings(files: { pattern: '*_test.rb', map_to_tests: 'minitest' })
        resolver = FileResolver.new(settings)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            # No test file exists
            result = resolver.resolve(['app/models/user.rb'])

            assert_empty result
          end
        end
      end

      def test_skip_returns_true_when_files_requested_but_none_match
        settings = build_settings(files: { pattern: '*.rb' })
        resolver = FileResolver.new(settings)

        assert resolver.skip?(['app.js', 'style.css'])
      end

      def test_skip_returns_false_when_no_files_requested
        settings = build_settings(files: { pattern: '*.rb' })
        resolver = FileResolver.new(settings)

        refute resolver.skip?([])
      end

      def test_skip_returns_false_when_files_match_pattern
        settings = build_settings(files: { pattern: '*.rb' })
        resolver = FileResolver.new(settings)

        refute resolver.skip?(['lib/reviewer.rb'])
      end

      private

      def build_settings(files:)
        config = { commands: { review: 'test' } }
        config[:files] = files if files
        Settings.new(:test_tool, config: config)
      end
    end
  end
end
