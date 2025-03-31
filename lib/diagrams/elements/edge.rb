# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents an edge or link between two nodes in a diagram.
    # Typically connects nodes via their IDs and can have an optional label.
    class Edge < Dry::Struct
      # Use the shared Types module defined in node.rb (or a dedicated types file)
      include Elements::Types

      # Consider if an edge needs its own ID, or if source/target/label is sufficient identity.
      # attribute :id, Types::Strict::String

      attribute :source_id, Types::Strict::String.constrained(min_size: 1)
      attribute :target_id, Types::Strict::String.constrained(min_size: 1)
      attribute :label, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | nil}]
      def to_h
        # Rely on Dry::Struct's default to_h, which includes all attributes.
        # Filter out nil label if desired.
        super.compact
      end
    end
  end
end
