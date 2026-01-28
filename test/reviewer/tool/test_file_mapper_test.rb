# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Tool
    class TestFileMapperTest < Minitest::Test
      def test_recognizes_minitest_framework
        mapper = TestFileMapper.new(:minitest)
        assert mapper.supported?
      end

      def test_recognizes_rspec_framework
        mapper = TestFileMapper.new(:rspec)
        assert mapper.supported?
      end

      def test_returns_unsupported_for_unknown_framework
        mapper = TestFileMapper.new(:unknown)
        refute mapper.supported?
      end

      def test_returns_unsupported_for_nil_framework
        mapper = TestFileMapper.new(nil)
        refute mapper.supported?
      end

      def test_maps_app_model_to_test_for_minitest
        mapper = TestFileMapper.new(:minitest)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('test/models')
            FileUtils.touch('test/models/user_test.rb')

            result = mapper.map(['app/models/user.rb'])
            assert_equal ['test/models/user_test.rb'], result
          end
        end
      end

      def test_maps_lib_file_to_spec_for_rspec
        mapper = TestFileMapper.new(:rspec)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('spec/reviewer')
            FileUtils.touch('spec/reviewer/tool_spec.rb')

            result = mapper.map(['lib/reviewer/tool.rb'])
            assert_equal ['spec/reviewer/tool_spec.rb'], result
          end
        end
      end

      def test_passes_through_existing_test_files_unchanged
        mapper = TestFileMapper.new(:minitest)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('test/models')
            FileUtils.touch('test/models/user_test.rb')

            result = mapper.map(['test/models/user_test.rb'])
            assert_equal ['test/models/user_test.rb'], result
          end
        end
      end

      def test_returns_empty_for_nonexistent_test_file
        mapper = TestFileMapper.new(:minitest)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            result = mapper.map(['app/models/user.rb'])
            assert_empty result
          end
        end
      end

      def test_handles_file_without_app_or_lib_prefix
        mapper = TestFileMapper.new(:minitest)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('test')
            FileUtils.touch('test/standalone_test.rb')

            result = mapper.map(['standalone.rb'])
            assert_equal ['test/standalone_test.rb'], result
          end
        end
      end

      def test_returns_files_unchanged_for_unsupported_framework
        mapper = TestFileMapper.new(:unknown)
        files = ['app/models/user.rb', 'lib/tool.rb']

        result = mapper.map(files)
        assert_equal files, result
      end

      def test_deduplicates_mapped_files
        mapper = TestFileMapper.new(:minitest)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            FileUtils.mkdir_p('test/models')
            FileUtils.touch('test/models/user_test.rb')

            result = mapper.map(['app/models/user.rb', 'app/models/user.rb'])
            assert_equal ['test/models/user_test.rb'], result
          end
        end
      end

      def test_handles_string_framework_name
        mapper = TestFileMapper.new('minitest')
        assert mapper.supported?
      end

      def test_excludes_non_ruby_files
        mapper = TestFileMapper.new(:minitest)

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            result = mapper.map(['app/assets/application.js'])
            assert_empty result
          end
        end
      end
    end
  end
end
