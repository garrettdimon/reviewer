# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class RunnerTest < MiniTest::Test
    def setup
      Reviewer.configure do |config|
        config.file = 'test/fixtures/files/test_commands.yml'
      end
    end

    def test_pending
      skip 'Pending Implentation'
    end
  end
end
