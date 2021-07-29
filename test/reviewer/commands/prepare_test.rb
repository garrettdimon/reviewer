# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Commands
    class PrepareTest < MiniTest::Test
      def setup
        allow_printing_output!
      end

      def teardown
        ensure_test_configuration!
      end

      def test_command
        skip "Reviewer::Command::PrepareTest"
      end
    end
  end
end
