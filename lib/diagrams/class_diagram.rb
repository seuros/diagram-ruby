# frozen_string_literal: true

module Diagrams
  # Represents a UML Class Diagram consisting of classes and relationships between them.
  class ClassDiagram < Base
    attr_reader :classes, :relationships

    # Initializes a new ClassDiagram.
    #
    # @param classes [Array<Element::ClassEntity>] An array of class entity objects.
    # @param relationships [Array<Element::Relationship>] An array of relationship objects.
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(classes: [], relationships: [], version: 1)
      super(version:)
      @classes = Array(classes)
      @relationships = Array(relationships)
      validate_elements!
      update_checksum!
    end

    # Adds a class entity to the diagram.
    #
    # @param class_entity [Element::ClassEntity] The class entity object to add.
    # @raise [ArgumentError] if a class with the same name already exists.
    # @return [Element::ClassEntity] The added class entity.
    def add_class(class_entity)
      unless class_entity.is_a?(Diagrams::Elements::ClassEntity)
        raise ArgumentError,
              'Class entity must be a Diagrams::Elements::ClassEntity'
      end
      raise ArgumentError, "Class with name '#{class_entity.name}' already exists" if find_class(class_entity.name)

      @classes << class_entity
      update_checksum!
      class_entity
    end

    # Adds a relationship to the diagram.
    #
    # @param relationship [Element::Relationship] The relationship object to add.
    # @raise [ArgumentError] if the relationship refers to non-existent class names.
    # @return [Element::Relationship] The added relationship.
    def add_relationship(relationship)
      unless relationship.is_a?(Diagrams::Elements::Relationship)
        raise ArgumentError,
              'Relationship must be a Diagrams::Elements::Relationship'
      end
      unless find_class(relationship.source_class_name) && find_class(relationship.target_class_name)
        raise ArgumentError,
              "Relationship refers to non-existent class names ('#{relationship.source_class_name}' or '#{relationship.target_class_name}')"
      end

      @relationships << relationship
      update_checksum!
      relationship
    end

    # Finds a class entity by its name.
    #
    # @param class_name [String] The name of the class to find.
    # @return [Element::ClassEntity, nil] The found class entity or nil.
    def find_class(class_name)
      @classes.find { |c| c.name == class_name }
    end

    # Returns the specific content of the class diagram as a hash.
    # Called by `Diagrams::Base#to_h`.
    #
    # @return [Hash{Symbol => Array<Hash>}]
    def to_h_content
      {
        classes: @classes.map(&:to_h),
        relationships: @relationships.map(&:to_h)
      }
    end

    # Returns a hash mapping element types to their collections for diffing.
    # @see Diagrams::Base#identifiable_elements
    # @return [Hash{Symbol => Array<Diagrams::Elements::ClassEntity | Diagrams::Elements::Relationship>}]
    def identifiable_elements
      {
        classes: @classes,
        relationships: @relationships
      }
    end

    # Class method to create a ClassDiagram from a hash.
    # Used by the deserialization factory in `Diagrams::Base`.
    #
    # @param data_hash [Hash] Hash containing `:classes` and `:relationships` arrays.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional, for verification).
    # @return [ClassDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      classes_data = data_hash[:classes] || data_hash['classes'] || []
      relationships_data = data_hash[:relationships] || data_hash['relationships'] || []

      classes = classes_data.map { |class_h| Diagrams::Elements::ClassEntity.new(class_h.transform_keys(&:to_sym)) }
      relationships = relationships_data.map do |rel_h|
        Diagrams::Elements::Relationship.new(rel_h.transform_keys(&:to_sym))
      end

      diagram = new(classes:, relationships:, version:)

      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded ClassDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
        # Or raise an error: raise "Checksum mismatch..."
      end

      diagram
    end

    private

    # Validates the consistency of classes and relationships during initialization.
    def validate_elements!
      class_names = @classes.map(&:name)
      raise ArgumentError, 'Duplicate class names found' unless class_names.uniq.size == @classes.size

      @relationships.each do |rel|
        unless class_names.include?(rel.source_class_name) && class_names.include?(rel.target_class_name)
          raise ArgumentError,
                "Relationship refers to non-existent class names ('#{rel.source_class_name}' or '#{rel.target_class_name}')"
        end
      end
    end
  end
end
