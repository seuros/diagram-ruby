# frozen_string_literal: true

module Diagrams
  # Represents an Entity Relationship Diagram (ERD).
  class ERDiagram < Base
    attr_reader :entities, :relationships

    # Initializes a new ERDiagram.
    #
    # @param entities [Array<Element::ERDEntity>] Initial entities (optional).
    # @param relationships [Array<Element::ERDRelationship>] Initial relationships (optional).
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(entities: [], relationships: [], version: 1)
      super(version:)
      @entities = (entities.is_a?(Array) ? entities : []).each_with_object({}) { |e, h| h[e.name] = e }
      @relationships = relationships.is_a?(Array) ? relationships : []
      validate_relationships!
      update_checksum!
    end

    # Adds an entity to the diagram.
    #
    # @param name [String] The unique name of the entity.
    # @param attributes [Array<Hash>] Array of attribute definitions (hashes like { type:, name:, keys:, comment: }).
    # @raise [ArgumentError] if an entity with the same name already exists.
    # @return [Elements::ERDEntity] The added entity.
    def add_entity(name:, attributes: [])
      raise ArgumentError, "Entity name '#{name}' cannot be empty" if name.nil? || name.strip.empty?
      raise ArgumentError, "Entity with name '#{name}' already exists" if @entities.key?(name)

      entity_attributes = attributes.map do |attr_hash|
        Elements::ERDAttribute.new(attr_hash.transform_keys(&:to_sym))
      end
      new_entity = Elements::ERDEntity.new(name:, entity_attributes: entity_attributes) # Use renamed attribute

      @entities[name] = new_entity
      update_checksum!
      new_entity
    end

    # Adds a relationship between two entities.
    #
    # @param entity1 [String] Name of the first entity.
    # @param entity2 [String] Name of the second entity.
    # @param cardinality1 [Symbol] Cardinality of entity1 relative to entity2 (e.g., :ONE_ONLY).
    # @param cardinality2 [Symbol] Cardinality of entity2 relative to entity1 (e.g., :ZERO_OR_MORE).
    # @param identifying [Boolean] Whether the relationship is identifying (default: false).
    # @param label [String, nil] Optional label describing the relationship action.
    # @raise [ArgumentError] if either entity does not exist.
    # @return [Elements::ERDRelationship] The added relationship.
    def add_relationship(entity1:, entity2:, cardinality1:, cardinality2:, identifying: false, label: nil)
      unless @entities.key?(entity1) && @entities.key?(entity2)
        raise ArgumentError, "One or both entities ('#{entity1}', '#{entity2}') not found for relationship."
      end

      new_relationship = Elements::ERDRelationship.new(
        entity1:,
        entity2:,
        cardinality1:,
        cardinality2:,
        identifying:,
        label:
      )
      @relationships << new_relationship
      update_checksum!
      new_relationship
    end

    # Finds an entity by its name.
    #
    # @param entity_name [String] The name of the entity to find.
    # @return [Elements::ERDEntity, nil] The found entity or nil.
    def find_entity(entity_name)
      @entities[entity_name]
    end

    # --- Base Class Implementation ---

    def to_h_content
      {
        entities: @entities.values.map(&:to_h),
        relationships: @relationships.map(&:to_h)
      }
    end

    def identifiable_elements
      {
        entities: @entities.values,
        relationships: @relationships # Relationships don't have a simple unique ID, rely on object equality for diff
      }
    end

    def self.from_h(data_hash, version:, checksum:)
      entities_data = data_hash[:entities] || data_hash['entities'] || []
      relationships_data = data_hash[:relationships] || data_hash['relationships'] || []

      entities = entities_data.map do |entity_h|
        entity_data = entity_h.transform_keys(&:to_sym)
        attributes_data = entity_data[:entity_attributes] || entity_data[:attributes] || [] # Accept both old and new key for now
        attributes = attributes_data.map do |attr_h|
          attr_data = attr_h.transform_keys(&:to_sym)
          # Convert keys back to symbols if they are strings
          # Convert keys back to symbols
          attr_data[:keys] = attr_data[:keys].map(&:to_sym) if attr_data[:keys].is_a?(Array)
          Elements::ERDAttribute.new(attr_data)
        end
        # Use the correct attribute name when creating the entity
        Elements::ERDEntity.new(entity_data.merge(entity_attributes: attributes))
      end

      relationships = relationships_data.map do |rel_h|
        rel_data = rel_h.transform_keys(&:to_sym)
        # Convert cardinalities back to symbols if they are strings
        rel_data[:cardinality1] = rel_data[:cardinality1].to_sym if rel_data[:cardinality1].is_a?(String)
        rel_data[:cardinality2] = rel_data[:cardinality2].to_sym if rel_data[:cardinality2].is_a?(String)
        Elements::ERDRelationship.new(rel_data)
      end

      diagram = new(entities:, relationships:, version:)

      # Optional: Verify checksum
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded ERDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
      end

      diagram
    end

    private

    # Validates that all relationships refer to existing entities during initialization.
    def validate_relationships!
      @relationships.each do |rel|
        unless @entities.key?(rel.entity1) && @entities.key?(rel.entity2)
          raise ArgumentError, "Relationship refers to non-existent entity IDs ('#{rel.entity1}' or '#{rel.entity2}')"
        end
      end
    end

    # Protected method access
    protected :update_checksum!
  end
end
