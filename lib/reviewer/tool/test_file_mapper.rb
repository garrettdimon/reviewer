# frozen_string_literal: true

module Reviewer
  class Tool
    # Maps source files to their corresponding test files based on framework conventions.
    class TestFileMapper
      FRAMEWORKS = {
        minitest: { dir: 'test', suffix: '_test.rb', source_dirs: %w[app lib] },
        rspec: { dir: 'spec', suffix: '_spec.rb', source_dirs: %w[app lib] }
      }.freeze

      # Creates a mapper for the specified test framework
      # @param framework [Symbol, String, nil] the test framework (:minitest or :rspec)
      #
      # @return [TestFileMapper] a mapper instance for the framework
      def initialize(framework)
        @framework = framework&.to_sym
      end

      # Maps source files to their corresponding test files
      # @param files [Array<String>] source files to map
      #
      # @return [Array<String>] mapped test files (only those that exist on disk)
      def map(files)
        return files unless supported?

        files.map { |file| map_file(file) }.compact.uniq
      end

      # Checks if the framework is supported for mapping
      #
      # @return [Boolean] true if the framework is :minitest or :rspec
      def supported?
        @framework && FRAMEWORKS.key?(@framework)
      end

      private

      def map_file(file)
        return file if test_file?(file)

        mapped = source_to_test(file)
        mapped && File.exist?(mapped) ? mapped : nil
      end

      def test_file?(file)
        file.end_with?(config[:suffix])
      end

      def source_to_test(file)
        return nil unless file.end_with?('.rb')

        replace_source_dir_with_test_dir(file).sub(/\.rb$/, config[:suffix])
      end

      def replace_source_dir_with_test_dir(path)
        config[:source_dirs].each do |dir|
          return path.sub(%r{^#{dir}/}, "#{config[:dir]}/") if path.start_with?("#{dir}/")
        end
        prepend_test_dir(path)
      end

      def prepend_test_dir(path)
        path.start_with?(config[:dir]) ? path : "#{config[:dir]}/#{path}"
      end

      def config
        FRAMEWORKS[@framework]
      end
    end
  end
end
