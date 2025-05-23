# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a relationship (e.g., association, inheritance) between two classes
    # in a UML Class Diagram.
    class Relationship < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      # Name of the source class
      attribute :source_class_name, Types::Strict::String.constrained(min_size: 1)

      # Name of the target class
      attribute :target_class_name, Types::Strict::String.constrained(min_size: 1)

      # Type of relationship (e.g., "association", "inheritance", "composition")
      # Consider using a constrained string or enum type later if needed.
      attribute :type, Types::Strict::String.constrained(min_size: 1)

      # Optional label for the relationship (e.g., multiplicity, role name)
      attribute :label, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | nil}]
      def to_h
        # Start with Dry::Struct's hash and drop nil attributes.
        super.compact
      end
    end
  end
end
