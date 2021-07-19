# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class HistoryTest < MiniTest::Test
    def setup
      @history = History.new
    end

    def test_initializes_yaml_store
      assert !@history.store.nil?
      assert_equal Reviewer.configuration.history_file, @history.file
    end

    def test_sets_and_gets_values
      @history.set(:tool, :key, 'value')
      assert_equal 'value', @history.get(:tool, :key)
    end

    def test_can_reset_history_store
      @history.set(:tool, :key, 'value')
      assert_equal 'value', @history.get(:tool, :key)

      @history.reset!
      assert_nil @history.get(:tool, :key)
    end
  end
end
