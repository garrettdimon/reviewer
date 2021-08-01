# frozen_string_literal: true

module Reviewer
  # Conversion functions for special types in Reviewer
  module Conversions
    def Tool(value)
      case value
      when Tool   then value
      when Symbol then Tool.new(value)
      when String then Tool.new(value.to_sym)
      else raise TypeError, "Cannot convert #{value.inspect} to Tool"
      end
    end
    module_function :Tool


    def Verbosity(value)
      case value
      when Command::Verbosity then value
      when Symbol             then Command::Verbosity.new(value)
      when String             then Command::Verbosity.new(value.to_sym)
      when Integer            then Command::Verbosity.new(Command::Verbosity::LEVELS[value])
      else raise TypeError, "Cannot convert #{value.inspect} to Verbosity"
      end
    end
    module_function :Verbosity
  end
end
