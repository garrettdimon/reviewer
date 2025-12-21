# frozen_string_literal: true

module Reviewer
  # Conversion functions for special types in Reviewer
  module Conversions
    def Tool(value) # rubocop:disable Naming/MethodName
      case value
      in Tool then value
      in Symbol then Tool.new(value)
      in String then Tool.new(value.to_sym)
      else raise TypeError, "Cannot convert #{value} to Tool"
      end
    end
    module_function :Tool
  end
end
