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

        result = resolver.resolve(['app/models/user.rb', 'app/assets/app.js', 'lib/tool.rb'])

        assert_equal ['app/models/user.rb', 'lib/tool.rb'], result
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

        refute resolver.skip?(['app/models/user.rb'])
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
