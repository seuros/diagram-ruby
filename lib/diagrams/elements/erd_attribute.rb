# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents an attribute within an ERD entity.
    class ERDAttribute < Dry::Struct
      include Elements::Types

      attribute :type, Types::Strict::String.constrained(min_size: 1)
      attribute :name, Types::Strict::String.constrained(min_size: 1)
      attribute :keys, Types::Strict::Array.of(Types::Strict::Symbol.enum(:PK, :FK, :UK)).default([].freeze)
      attribute :comment, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<Symbol>}]
      def to_h
        hash = {
          type:,
          name:,
          keys: keys.map(&:to_s) # Convert symbols to strings for serialization
        }
        hash[:comment] = comment if comment
        hash
      end
    end
  end
end
