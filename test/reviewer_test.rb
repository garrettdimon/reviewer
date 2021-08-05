# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ReviewerTest < Minitest::Test
    # def setup
    #   Reviewer.reset
    #   Reviewer.configure do |config|
    #     config.file = Pathname('test/fixtures/files/test_commands_runnable.yml')
    #   end
    # end

    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_returns_largest_exit_status
      tools = [Tool.new(:list), Tool.new(:enabled_tool), Tool.new(:missing_command), Tool.new(:failing_command)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          assert_equal 127, e.status
        end
      end
    end

    def test_review_command
      tools = [Tool.new(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_format_command
      tools = [Tool.new(:enabled_tool)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.format
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_clear_screen
      tools = [Tool.new(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review(clear_screen: true)
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end
  end
end
