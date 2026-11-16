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

      -String.new(value)
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

    # Integers beyond 2**53 are not held exactly by a JSON number as most
    # readers (JavaScript, so Mermaid) parse it: an IEEE double.
    EXACT_INTEGER = 2**53

    # Integer (up to 2**53) or finite Float: the numbers JSON carries and
    # reads back exactly.
    def non_negative(value, name)
      raise TypeError, "#{name} must be an Integer or Float, got #{value.class}" unless value in Integer | Float
      raise RangeError, "#{name} must be finite and >= 0, got #{value}" unless value.finite? && value >= 0
      if value.is_a?(Integer) && value > EXACT_INTEGER
        raise RangeError, "#{name} must be at most 2**53 to stay exact in a JSON number, got #{value}"
      end

      value
    end

    # A whole number JSON (and JavaScript) holds exactly: 0..2**53.
    def integer(value, name)
      raise TypeError, "#{name} must be an Integer, got #{value.class}" unless value.is_a?(Integer)
      raise RangeError, "#{name} must be between 0 and 2**53, got #{value}" unless value.between?(0, EXACT_INTEGER)

      value
    end

    # A diagram version: a String, an Integer or nil, which JSON (and so
    # from_h) give back unchanged.
    def version(value)
      return value if value.nil?
      return integer(value, :version) if value.is_a?(Integer)
      return -String.new(value) if value.is_a?(String)

      raise TypeError, "version must be a String, Integer or nil, got #{value.class}"
    end

    # Child elements, given as elements or as hashes of their members. Both are
    # rebuilt through +type+.from_h, so a subclass or an unchecked copy never
    # gets in.
    def elements(values, name, type)
      list(values, name).map do |value|
        case value
        when type then type.from_h(value.to_h)
        when Hash then type.from_h(value)
        else raise TypeError, "#{name} must contain #{type.name} or Hash, got #{value.class}"
        end
      end.freeze
    end

    def record(value, name)
      return value if value.is_a?(Hash)

      raise TypeError, "#{name} must be a Hash, got #{value.class}"
    end

    def list(values, name)
      return values if values.is_a?(Array)

      raise TypeError, "#{name} must be an Array, got #{values.class}"
    end

    # Hash keys as symbols, all the way down (JSON gives strings).
    def symbolize(value)
      case value
      when Hash then value.to_h { |key, item| [symbol_key(key), symbolize(item)] }
      when Array then value.map { symbolize(it) }
      else value
      end
    end

    def symbol_key(key)
      return key.to_sym if key in String | Symbol

      raise TypeError, "hash keys must be Strings or Symbols, got #{key.class}"
    end
  end
end
