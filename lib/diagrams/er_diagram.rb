# frozen_string_literal: true

module Diagrams
  # Entities, their attributes, and the relationships between them.
  class ERDiagram < Base
    collection :entities, add: :add_entity
    collection :relationships, add: :add_relationship

    # +attributes+ are ERDAttribute values or hashes of their members.
    def add_entity(name:, attributes: []) = append(:entities, Elements::ERDEntity.new(name:, attributes:))

    def add_relationship(entity1:, entity2:, cardinality1:, cardinality2:, identifying: false, label: nil)
      relationship = Elements::ERDRelationship.new(entity1:, entity2:, cardinality1:, cardinality2:, identifying:,
                                                   label:)
      find!(:entities, relationship.entity1, 'entity')
      find!(:entities, relationship.entity2, 'entity')
      append(:relationships, relationship)
    end
  end
end
