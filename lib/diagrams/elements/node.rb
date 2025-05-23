# frozen_string_literal: true

module Diagrams
  # Namespace for diagram element value objects.

  module Elements
    # Represents a node in various diagram types (e.g., Flowchart).
    # Typically has an identifier and a display label.
    class Node < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      attribute :id, Types::Strict::String.constrained(min_size: 1)
      attribute :label, Types::Strict::String.constrained(min_size: 1)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String}]
      def to_h
        {
          id:,
          label:
        }
      end
    end
  end
end
