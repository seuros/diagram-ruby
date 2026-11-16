# frozen_string_literal: true

module Diagrams
  # Classes and the relationships between them.
  class ClassDiagram < Base
    collection :classes, add: :add_class
    collection :relationships, add: :add_relationship

    def add_class(name:, attributes: [], operations: [])
      append(:classes, Elements::ClassEntity.new(name:, attributes:, operations:))
    end

    def add_relationship(source_class_name:, target_class_name:, type:, label: nil)
      relationship = Elements::Relationship.new(source_class_name:, target_class_name:, type:, label:)
      find!(:classes, relationship.source_class_name, 'class')
      find!(:classes, relationship.target_class_name, 'class')
      append(:relationships, relationship)
    end
  end
end
