# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Arguments
    class KeywordsTest < MiniTest::Test
      def setup
        @keywords_array = %w[staged]
        @files = Files.new(
          provided: @keywords_array
        )
      end

      def test_defaults_to_arguments_for_files_keywords
        skip 'TODO'
        # files = ::Reviewer::Arguments::Files.new
        # assert_equal ::Reviewer.arguments.files, files.files
        # assert_equal ::Reviewer.arguments.keywords, files.keywords
      end
    end
  end
end
