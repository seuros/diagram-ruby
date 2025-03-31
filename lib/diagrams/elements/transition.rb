# frozen_string_literal: true

module Diagrams
  module Elements
    # Represents a transition between two states in a State Diagram.
    class Transition < Dry::Struct
      # Use the shared Types module
      include Elements::Types

      # Consider if a transition needs its own ID.
      # attribute :id, Types::Strict::String

      attribute :source_state_id, Types::Strict::String.constrained(min_size: 1)
      attribute :target_state_id, Types::Strict::String.constrained(min_size: 1)
      # Label often represents the event or condition triggering the transition.
      attribute :label, Types::Strict::String.optional.default(nil)

      # Returns a hash representation suitable for serialization.
      #
      # @return [Hash{Symbol => String | nil}]
      def to_h
        # Rely on Dry::Struct's default to_h, filtering out nil label.
        super.compact
      end
    end
  end
end
