# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class FilesTest < Minitest::Test
      def test_array_casting
        assert_equal [], Files.new.to_a
        assert_equal ['*.css', '*.rb'], Files.new(provided: ['*.rb', '*.css'], keywords: []).to_a
      end

      def test_string_casting
        assert_equal '', Files.new.to_s
        assert_equal '*.css,*.rb', Files.new(provided: ['*.rb', '*.css'], keywords: []).to_s
      end

      def test_raw_aliases_provided
        files = Files.new
        assert_equal files.provided, files.raw
      end

      def test_generating_files_from_flags
        files_array = ['*.css', '*.rb']
        files = Files.new(
          provided: files_array,
          keywords: []
        )

        assert_equal files_array.sort, files.to_a
      end

      def test_casting_to_hash
        files = Files.new
        assert files.to_h.key?(:provided)
        assert files.to_h.key?(:from_keywords)
      end

      def test_skips_generating_files_from_keywords_if_the_keyword_is_not_a_defined_method
        keywords_array = %w[not_a_real_keyword]
        files = Files.new(
          provided: [],
          keywords: keywords_array
        )

        assert_empty files.to_h[:from_keywords]
      end

      def test_generating_files_from_keywords
        staged_files = ['lib/reviewer.rb']
        keywords_array = %w[staged]
        files = Files.new(
          provided: [],
          keywords: keywords_array
        )

        ::Reviewer::Keywords::Git::Staged.stub :list, staged_files do
          assert_equal staged_files, files.to_a
        end
      end

      def test_generating_files_from_flags_and_keywords
        staged_files = ['lib/reviewer.rb']
        files_array = ['*.css', '*.rb']
        full_files_array = staged_files + files_array

        keywords_array = %w[staged]
        files = Files.new(
          provided: files_array,
          keywords: keywords_array
        )

        # Stub the call to Git::Staged to avoid the need to run Git commands
        # in tests to setup fake staged files
        ::Reviewer::Keywords::Git::Staged.stub :list, staged_files do
          assert_equal full_files_array.sort, files.to_a
        end
      end
    end
  end
end
