# frozen_string_literal: true

module Reviewer
  class Tool
    # Conversion functions for coercing values to Tool instances
    module Conversions
      # Coerces a value into a Tool instance
      # @param value [Tool] the value to convert
      # @return [Tool] the resulting Tool instance
      # @raise [TypeError] if the value is not a Tool
      def Tool(value) # rubocop:disable Naming/MethodName
        case value
        in Tool then value
        else raise TypeError, "Cannot convert #{value.class} to Tool"
        end
      end
      module_function :Tool
    end
  end
end
