# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class PromptTest < Minitest::Test
    def test_yes_response_returns_true
      input = tty_input("y\n")
      output = StringIO.new
      prompt = Prompt.new(input: input, output: output)

      assert prompt.yes?('Set up now?')
      assert_match(%r{Set up now\? \(y/n\)}, output.string)
    end

    def test_yes_uppercase_returns_true
      input = tty_input("Y\n")
      prompt = Prompt.new(input: input, output: StringIO.new)

      assert prompt.yes?('Set up now?')
    end

    def test_yes_word_returns_true
      input = tty_input("yes\n")
      prompt = Prompt.new(input: input, output: StringIO.new)

      assert prompt.yes?('Set up now?')
    end

    def test_no_response_returns_false
      input = tty_input("n\n")
      prompt = Prompt.new(input: input, output: StringIO.new)

      refute prompt.yes?('Set up now?')
    end

    def test_empty_response_returns_false
      input = tty_input("\n")
      prompt = Prompt.new(input: input, output: StringIO.new)

      refute prompt.yes?('Set up now?')
    end

    def test_eof_returns_false
      input = tty_input('')
      prompt = Prompt.new(input: input, output: StringIO.new)

      refute prompt.yes?('Set up now?')
    end

    def test_non_tty_returns_false_without_prompting
      input = StringIO.new("y\n")
      output = StringIO.new
      prompt = Prompt.new(input: input, output: output)

      refute prompt.yes?('Set up now?')
      assert_empty output.string
    end

    private

    # Creates a StringIO that reports itself as a TTY
    def tty_input(text)
      io = StringIO.new(text)
      io.define_singleton_method(:tty?) { true }
      io
    end
  end
end
