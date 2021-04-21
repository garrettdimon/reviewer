# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil VERSION
    end
  end
end
