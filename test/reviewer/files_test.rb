# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class FilesTest < MiniTest::Test
    def setup
      @files_array = ['*.rb', '*.css']
      @keywords_array = %w[staged]
      @files = Files.new(
        files: @files_array,
        keywords: @keywords_array
      )
    end

    def test_defaults_to_arguments_for_files_keywords
      files = ::Reviewer::Files.new
      assert_equal ::Reviewer.arguments.files, files.files
      assert_equal ::Reviewer.arguments.keywords, files.keywords
    end

    def test_can_be_initialized_with_nonargument_values
      assert_equal @files_array, @files.files
      assert_equal @keywords_array, @files.keywords
    end

    def test_can_be_converted_to_array
      assert @files.to_a.is_a?(Array)
    end

    def test_can_be_converted_to_string
      assert @files.to_s.is_a?(String)
    end
  end
end
