# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Git
    class StagedTest < MiniTest::Test
      def setup
        @staged = Reviewer::Git::Staged.new
      end

      def test_lists_staged_files
        list = @staged.list
        assert list.is_a?(Array)
      end
    end
  end
end
