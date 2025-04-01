# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents an entity (table) in an ER Diagram.
    class ERDEntity < Dry::Struct
      include Elements::Types

      attribute :name, Types::Strict::String.constrained(min_size: 1)
      attribute :entity_attributes, Types::Strict::Array.of(ERDAttribute).default([].freeze)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | Array<Hash>}]
      def to_h
        {
          name: name,
          attributes: entity_attributes.map(&:to_h) # Renamed variable
        }
      end
    end
  end
end
