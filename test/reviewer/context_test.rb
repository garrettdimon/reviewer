# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ContextTest < Minitest::Test
    def test_exposes_arguments
      context = Context.new(arguments: :args, output: :out, history: :hist)
      assert_equal :args, context.arguments
    end

    def test_exposes_output
      context = Context.new(arguments: :args, output: :out, history: :hist)
      assert_equal :out, context.output
    end

    def test_exposes_history
      context = Context.new(arguments: :args, output: :out, history: :hist)
      assert_equal :hist, context.history
    end

    def test_members_are_readable
      context = Context.new(arguments: :args, output: :out, history: :hist)
      assert_equal %i[arguments output history], context.members
    end
  end
end
