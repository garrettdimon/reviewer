# frozen_string_literal: true

module Reviewer
  # Conversion functions for special types in Reviewer
  module Conversions
    def Tool(value) # rubocop:disable Naming/MethodName
      case value
      when Tool   then value
      when Symbol then Tool.new(value)
      when String then Tool.new(value.to_sym)
      else raise TypeError, "Cannot convert #{value} to Tool"
      end
    end
    module_function :Tool
  end
end
