# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a relationship between two entities in an ER Diagram.
    class ERDRelationship < Dry::Struct
      include Elements::Types

      # Cardinality symbols (Crow's Foot notation mapping)
      CARDINALITY = Types::Strict::Symbol.enum(
        :ZERO_OR_ONE,  # |o
        :ONE_ONLY,     # ||
        :ZERO_OR_MORE, # }o
        :ONE_OR_MORE   # }|
      )

      attribute :entity1, Types::Strict::String.constrained(min_size: 1)
      attribute :entity2, Types::Strict::String.constrained(min_size: 1)
      attribute :cardinality1, CARDINALITY # Cardinality of entity1 relative to entity2
      attribute :cardinality2, CARDINALITY # Cardinality of entity2 relative to entity1
      attribute :identifying, Types::Strict::Bool.default(false) # Is it an identifying relationship? (solid vs dashed line)
      attribute :label, Types::Strict::String.optional.default(nil) # Optional action/verb phrase

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Symbol | Bool}]
      def to_h
        hash = {
          entity1: entity1,
          entity2: entity2,
          cardinality1: cardinality1.to_s, # Convert symbol to string
          cardinality2: cardinality2.to_s, # Convert symbol to string
          identifying: identifying
        }
        hash[:label] = label if label
        hash
      end
    end
  end
end
