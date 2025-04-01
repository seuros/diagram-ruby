# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class ERDiagramTest < Minitest::Test
    def setup
      @diagram = ERDiagram.new
    end

    def test_initialization
      assert_instance_of ERDiagram, @diagram
      assert_empty @diagram.entities
      assert_empty @diagram.relationships
      refute_nil @diagram.checksum
    end

    def test_add_entity
      entity = @diagram.add_entity(name: 'CUSTOMER')

      assert_equal 1, @diagram.entities.size
      assert_equal entity, @diagram.entities['CUSTOMER']
      assert_equal 'CUSTOMER', entity.name
      assert_empty entity.entity_attributes
    end

    def test_add_entity_with_attributes
      attributes = [
        { type: 'string', name: 'name' },
        { type: 'int', name: 'customer_id', keys: [:PK], comment: 'Primary Key' }
      ]
      entity = @diagram.add_entity(name: 'CUSTOMER', attributes:)

      assert_equal 2, entity.entity_attributes.size
      assert_equal 'string', entity.entity_attributes[0].type
      assert_equal 'name', entity.entity_attributes[0].name
      assert_empty entity.entity_attributes[0].keys
      assert_nil entity.entity_attributes[0].comment

      assert_equal 'int', entity.entity_attributes[1].type
      assert_equal 'customer_id', entity.entity_attributes[1].name
      assert_equal [:PK], entity.entity_attributes[1].keys
      assert_equal 'Primary Key', entity.entity_attributes[1].comment
    end

    def test_add_entity_duplicate_name
      @diagram.add_entity(name: 'CUSTOMER')
      assert_raises(ArgumentError, /Entity with name 'CUSTOMER' already exists/) do
        @diagram.add_entity(name: 'CUSTOMER')
      end
    end

    def test_add_relationship
      e1 = @diagram.add_entity(name: 'CUSTOMER')
      e2 = @diagram.add_entity(name: 'ORDER')
      rel = @diagram.add_relationship(
        entity1: e1.name,
        entity2: e2.name,
        cardinality1: :ONE_ONLY,
        cardinality2: :ZERO_OR_MORE,
        label: 'places'
      )

      assert_equal 1, @diagram.relationships.size
      assert_equal rel, @diagram.relationships.first
      assert_equal 'CUSTOMER', rel.entity1
      assert_equal 'ORDER', rel.entity2
      assert_equal :ONE_ONLY, rel.cardinality1
      assert_equal :ZERO_OR_MORE, rel.cardinality2
      assert_equal 'places', rel.label
      refute rel.identifying
    end

    def test_add_identifying_relationship
      e1 = @diagram.add_entity(name: 'ORDER')
      e2 = @diagram.add_entity(name: 'LINE-ITEM')
      rel = @diagram.add_relationship(
        entity1: e1.name,
        entity2: e2.name,
        cardinality1: :ONE_ONLY,
        cardinality2: :ONE_OR_MORE,
        identifying: true,
        label: 'contains'
      )

      assert rel.identifying
    end

    def test_add_relationship_unknown_entity
      @diagram.add_entity(name: 'CUSTOMER')
      assert_raises(ArgumentError, /One or both entities \('CUSTOMER', 'ORDER'\) not found/) do
        @diagram.add_relationship(
          entity1: 'CUSTOMER',
          entity2: 'ORDER', # ORDER does not exist
          cardinality1: :ONE_ONLY,
          cardinality2: :ZERO_OR_MORE
        )
      end
    end

    def test_find_entity
      entity = @diagram.add_entity(name: 'CUSTOMER')

      assert_equal entity, @diagram.find_entity('CUSTOMER')
      assert_nil @diagram.find_entity('UNKNOWN')
    end

    def test_serialization_deserialization
      # Build a complex diagram
      @diagram.add_entity(name: 'CUSTOMER', attributes: [
                            { type: 'int', name: 'id', keys: [:PK] },
                            { type: 'string', name: 'name' }
                          ])
      @diagram.add_entity(name: 'ORDER', attributes: [
                            { type: 'int', name: 'order_id', keys: [:PK] },
                            { type: 'int', name: 'customer_id', keys: [:FK] },
                            { type: 'date', name: 'order_date' }
                          ])
      @diagram.add_entity(name: 'PRODUCT', attributes: [
                            { type: 'string', name: 'sku', keys: [:PK] },
                            { type: 'string', name: 'description' },
                            { type: 'decimal', name: 'price' }
                          ])
      @diagram.add_entity(name: 'ORDER_ITEM', attributes: [
                            { type: 'int', name: 'order_id', keys: %i[PK FK] },
                            { type: 'string', name: 'product_sku', keys: %i[PK FK] },
                            { type: 'int', name: 'quantity' }
                          ])

      @diagram.add_relationship(entity1: 'CUSTOMER', entity2: 'ORDER', cardinality1: :ONE_ONLY,
                                cardinality2: :ZERO_OR_MORE, label: 'places')
      @diagram.add_relationship(entity1: 'ORDER', entity2: 'ORDER_ITEM', cardinality1: :ONE_ONLY,
                                cardinality2: :ZERO_OR_MORE, identifying: true, label: 'contains')
      @diagram.add_relationship(entity1: 'PRODUCT', entity2: 'ORDER_ITEM', cardinality1: :ONE_ONLY,
                                cardinality2: :ZERO_OR_MORE, identifying: true, label: 'details')

      original_checksum = @diagram.checksum
      diagram_hash = @diagram.to_h
      reloaded_diagram = Diagrams::Base.from_hash(diagram_hash)

      assert_instance_of ERDiagram, reloaded_diagram
      assert_equal @diagram.version, reloaded_diagram.version
      assert_equal @diagram.entities.keys.sort, reloaded_diagram.entities.keys.sort
      assert_equal @diagram.relationships.size, reloaded_diagram.relationships.size
      assert_equal original_checksum, reloaded_diagram.checksum
      assert_equal @diagram, reloaded_diagram

      # Check details
      reloaded_customer = reloaded_diagram.find_entity('CUSTOMER')

      assert_equal 2, reloaded_customer.entity_attributes.size
      assert_equal [:PK], reloaded_customer.entity_attributes[0].keys

      reloaded_rel = reloaded_diagram.relationships.find { |r| r.label == 'contains' }

      assert reloaded_rel.identifying
      assert_equal :ZERO_OR_MORE, reloaded_rel.cardinality2
    end

    # --- Diffing Tests ---

    def test_diff_identical
      diagram1 = ERDiagram.new
      diagram1.add_entity(name: 'E1')
      diagram1.add_entity(name: 'E2')
      diagram1.add_relationship(entity1: 'E1', entity2: 'E2', cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE)

      diagram2 = ERDiagram.new
      diagram2.add_entity(name: 'E1')
      diagram2.add_entity(name: 'E2')
      diagram2.add_relationship(entity1: 'E1', entity2: 'E2', cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE)

      assert_empty diagram1.diff(diagram2)
    end

    def test_diff_added_entity
      diagram1 = ERDiagram.new
      diagram1.add_entity(name: 'E1')

      diagram2 = ERDiagram.new
      diagram2.add_entity(name: 'E1')
      entity2 = diagram2.add_entity(name: 'E2') # Added

      diff = diagram1.diff(diagram2)

      assert_equal 1, diff.size
      assert diff.key?(:entities)
      assert diff[:entities].key?(:added)
      assert_equal [entity2], diff[:entities][:added]
      refute diff[:entities].key?(:removed)
      refute diff[:entities].key?(:modified)
    end

    def test_diff_removed_entity
      diagram1 = ERDiagram.new
      diagram1.add_entity(name: 'E1')
      entity2 = diagram1.add_entity(name: 'E2') # Removed

      diagram2 = ERDiagram.new
      diagram2.add_entity(name: 'E1')

      diff = diagram1.diff(diagram2)

      assert_equal 1, diff.size
      assert diff.key?(:entities)
      assert diff[:entities].key?(:removed)
      assert_equal [entity2], diff[:entities][:removed]
      refute diff[:entities].key?(:added)
      refute diff[:entities].key?(:modified)
    end

    # Basic modification check
    def test_diff_modified_entity_attribute
      diagram1 = ERDiagram.new
      entity1_v1 = diagram1.add_entity(name: 'E1', attributes: [{ type: 'int', name: 'id' }])

      diagram2 = ERDiagram.new
      entity1_v2 = diagram2.add_entity(name: 'E1', attributes: [{ type: 'int', name: 'id', keys: [:PK] }]) # Added PK

      diff = diagram1.diff(diagram2)

      assert_equal 1, diff.size
      assert diff.key?(:entities)
      assert diff[:entities].key?(:modified)
      assert_equal 1, diff[:entities][:modified].size
      mod = diff[:entities][:modified].first

      assert_equal entity1_v1, mod[:old]
      assert_equal entity1_v2, mod[:new]
      refute diff[:entities].key?(:added)
      refute diff[:entities].key?(:removed)
    end

    def test_diff_added_relationship
      diagram1 = ERDiagram.new
      diagram1.add_entity(name: 'E1')
      diagram1.add_entity(name: 'E2')

      diagram2 = ERDiagram.new
      diagram2.add_entity(name: 'E1')
      diagram2.add_entity(name: 'E2')
      rel1 = diagram2.add_relationship(entity1: 'E1', entity2: 'E2', cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE) # Added

      diff = diagram1.diff(diagram2)

      assert_equal 1, diff.size
      assert diff.key?(:relationships)
      assert diff[:relationships].key?(:added)
      assert_equal [rel1], diff[:relationships][:added]
      refute diff[:relationships].key?(:removed)
      refute diff[:relationships].key?(:modified)
    end

    def test_diff_removed_relationship
      diagram1 = ERDiagram.new
      diagram1.add_entity(name: 'E1')
      diagram1.add_entity(name: 'E2')
      rel1 = diagram1.add_relationship(entity1: 'E1', entity2: 'E2', cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE) # Removed

      diagram2 = ERDiagram.new
      diagram2.add_entity(name: 'E1')
      diagram2.add_entity(name: 'E2')

      diff = diagram1.diff(diagram2)

      assert_equal 1, diff.size
      assert diff.key?(:relationships)
      assert diff[:relationships].key?(:removed)
      assert_equal [rel1], diff[:relationships][:removed]
      refute diff[:relationships].key?(:added)
      refute diff[:relationships].key?(:modified)
    end

    # Basic modification check
    def test_diff_modified_relationship_label
      diagram1 = ERDiagram.new
      diagram1.add_entity(name: 'E1')
      diagram1.add_entity(name: 'E2')
      rel_v1 = diagram1.add_relationship(entity1: 'E1', entity2: 'E2', cardinality1: :ONE_ONLY,
                                         cardinality2: :ZERO_OR_MORE, label: 'holds')

      diagram2 = ERDiagram.new
      diagram2.add_entity(name: 'E1')
      diagram2.add_entity(name: 'E2')
      rel_v2 = diagram2.add_relationship(entity1: 'E1', entity2: 'E2', cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE, label: 'contains') # Changed label

      diff = diagram1.diff(diagram2)
      # NOTE: Relationships don't have a simple ID, so diff relies on object equality.
      # A change creates a new object, so it appears as removed/added.
      assert_equal 1, diff.size
      assert diff.key?(:relationships)
      assert diff[:relationships].key?(:removed)
      assert diff[:relationships].key?(:added)
      assert_equal [rel_v1], diff[:relationships][:removed]
      assert_equal [rel_v2], diff[:relationships][:added]
      refute diff[:relationships].key?(:modified)
    end
  end
end
