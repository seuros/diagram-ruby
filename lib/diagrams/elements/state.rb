# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a state in a State Diagram.
    class State < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      attribute :id, Types::Strict::String.constrained(min_size: 1)
      attribute :label, Types::Strict::String.optional.default(nil)
      # TODO: Consider adding back type attribute (e.g., start, end, state)
      # attribute :type, Types::Strict::String.enum('state', 'start', 'end', 'fork', 'join').default('state')

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
