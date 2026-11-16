# frozen_string_literal: true

module Diagrams
  module Elements
    # A relationship between two entities. +cardinality1+ is how many of
    # entity1 relate to one entity2, and +cardinality2+ the reverse. An
    # identifying relationship is drawn solid, a non-identifying one dashed.
    ERDRelationship = Data.define(:entity1, :entity2, :cardinality1, :cardinality2, :identifying, :label) do
      include Element

      def initialize(entity1:, entity2:, cardinality1:, cardinality2:, identifying: false, label: nil)
        super(
          entity1: Check.string(entity1, :entity1),
          entity2: Check.string(entity2, :entity2),
          cardinality1: Check.symbol(cardinality1, :cardinality1, ERDRelationship::CARDINALITIES),
          cardinality2: Check.symbol(cardinality2, :cardinality2, ERDRelationship::CARDINALITIES),
          identifying: Check.boolean(identifying, :identifying),
          label: Check.optional_string(label, :label)
        )
      end
    end

    ERDRelationship::CARDINALITIES = %i[ZERO_OR_ONE ONE_ONLY ZERO_OR_MORE ONE_OR_MORE].freeze
  end
end
