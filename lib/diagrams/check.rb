# frozen_string_literal: true

module Diagrams
  # Argument checks shared by elements and diagrams. A value of the wrong
  # class raises TypeError; a value of the right class that is not allowed
  # raises ArgumentError (or RangeError for numbers).
  module Check
    module_function

    def string(value, name)
      raise TypeError, "#{name} must be a String, got #{value.class}" unless value.is_a?(String)
      raise ArgumentError, "#{name} cannot be blank" if value.strip.empty?

      -value
    end

    def optional_string(value, name) = value.nil? ? nil : string(value, name)

    def strings(values, name) = list(values, name).map { string(it, name) }.freeze

    def boolean(value, name)
      return value if [true, false].include?(value)

      raise TypeError, "#{name} must be true or false, got #{value.class}"
    end

    # A Symbol (or its String name, as JSON has it) from a fixed set.
    def symbol(value, name, allowed)
      raise TypeError, "#{name} must be a Symbol, got #{value.class}" unless value in Symbol | String

      symbol = value.to_sym
      return symbol if allowed.include?(symbol)

      raise ArgumentError, "#{name} must be one of #{allowed.join(', ')}, got #{symbol}"
    end

    def non_negative(value, name)
      raise TypeError, "#{name} must be Numeric, got #{value.class}" unless value.is_a?(Numeric)
      raise RangeError, "#{name} must be finite and >= 0, got #{value}" unless value.finite? && value >= 0

      value
    end

    # Child elements, given as elements or as hashes of their members.
    def elements(values, name, type)
      list(values, name).map do |value|
        case value
        when type then value
        when Hash then type.from_h(value)
        else raise TypeError, "#{name} must contain #{type.name} or Hash, got #{value.class}"
        end
      end.freeze
    end

    def list(values, name)
      return values if values.is_a?(Array)

      raise TypeError, "#{name} must be an Array, got #{values.class}"
    end

    # Hash keys as symbols, all the way down (JSON gives strings).
    def symbolize(value)
      case value
      when Hash then value.to_h { |key, item| [key.to_sym, symbolize(item)] }
      when Array then value.map { symbolize(it) }
      else value
      end
    end
  end
end
