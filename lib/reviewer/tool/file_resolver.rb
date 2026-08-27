# frozen_string_literal: true

module Reviewer
  class Tool
    # Resolves which files a tool should process by mapping and filtering.
    class FileResolver
      # Creates a FileResolver for a tool's settings
      # @param settings [Tool::Settings] the tool's settings containing file configuration
      #
      # @return [FileResolver] a resolver instance for the tool
      def initialize(settings)
        @settings = settings
      end

      # Resolves input files by mapping source files to test files (if configured), filtering by
      # the tool's file pattern, and omitting paths that do not exist
      # @param files [Array<String>] the input files to resolve
      #
      # @return [Array<String>] files after mapping and filtering
      def resolve(files)
        return files unless settings.supports_files?

        resolved = map(files)
        resolved = filter(resolved) if pattern
        resolved.select { |file| File.exist?(file) }
      end

      # Determines if the tool should be skipped because files were requested but none match
      # @param files [Array<String>] the requested files
      #
      # @return [Boolean] true if files were requested but none remain after resolution
      def skip?(files)
        files.any? && resolve(files).empty?
      end

      private

      attr_reader :settings

      def map(files)
        mapper = settings.map_to_tests
        return files unless mapper

        TestFileMapper.new(mapper).map(files)
      end

      def filter(files)
        files.select do |file|
          if pattern.include?('/')
            candidate = file.delete_prefix("#{Dir.pwd}/").delete_prefix('./')
            File.fnmatch(pattern, candidate, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          else
            File.fnmatch(pattern, File.basename(file))
          end
        end
      end

      def pattern
        settings.files_pattern
      end
    end
  end
end
