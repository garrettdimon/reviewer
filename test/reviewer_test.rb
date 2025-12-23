# frozen_string_literal: true

require 'test_helper'

module Reviewer
  # Stub for testing different argument configurations
  StubArgs = Struct.new(:format, :json?, :raw?, :streaming?, keyword_init: true)

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

    def test_summary_format_outputs_checkmarks
      tools = [Tool.new(:list)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :summary, json?: false, raw?: false, streaming?: false)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          assert_match(/✓/, out)
          assert_match(/All passed/i, out)
        end
      end
    end

    def test_json_format_outputs_json
      tools = [Tool.new(:list)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :json, json?: true, raw?: false, streaming?: false)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          assert_match(/"success":\s*true/, out)
          assert_match(/"tools":/, out)
        end
      end
    end
  end
end
