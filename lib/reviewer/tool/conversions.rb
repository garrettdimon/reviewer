# frozen_string_literal: true

module Reviewer
  class Tool
    # Conversion functions for coercing values to Tool instances
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
end
