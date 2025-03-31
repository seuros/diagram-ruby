# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class ClassDiagramTest < DiagramTest
    def setup
      @class1 = Elements::ClassEntity.new(name: 'User', attributes: ['id: Integer', 'name: String'],
                                          methods: ['save()'])
      @class2 = Elements::ClassEntity.new(name: 'Order', attributes: ['order_id: Integer', 'total: Float'])
      @class3 = Elements::ClassEntity.new(name: 'AdminUser', attributes: ['admin_level: Integer'],
                                          methods: ['ban_user()'])
      @rel1 = Elements::Relationship.new(source_class_name: 'User', target_class_name: 'Order', type: 'has_many',
                                         label: 'orders')
      @rel2 = Elements::Relationship.new(source_class_name: 'AdminUser', target_class_name: 'User', type: 'inheritance')
    end

    def test_initialize_empty
      diagram = ClassDiagram.new

      assert_empty diagram.classes
      assert_empty diagram.relationships
      assert_equal 1, diagram.version
      refute_nil diagram.checksum
    end

    def test_initialize_with_elements
      diagram = ClassDiagram.new(classes: [@class1, @class2], relationships: [@rel1], version: '2.0')

      assert_equal [@class1, @class2], diagram.classes
      assert_equal [@rel1], diagram.relationships
      assert_equal '2.0', diagram.version
    end

    def test_initialize_validates_duplicate_class_name
      error = assert_raises(ArgumentError) do
        ClassDiagram.new(classes: [@class1, @class1])
      end
      assert_match(/Duplicate class names found/, error.message)
    end

    def test_initialize_validates_relationship_classes
      error = assert_raises(ArgumentError) do
        ClassDiagram.new(classes: [@class1], relationships: [@rel1]) # rel1 needs Order class
      end
      assert_match(/Relationship refers to non-existent class names/, error.message)
    end

    def test_add_class
      diagram = ClassDiagram.new
      initial_checksum = diagram.checksum
      diagram.add_class(@class1)

      assert_equal [@class1], diagram.classes
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_class_duplicate_name
      diagram = ClassDiagram.new(classes: [@class1])
      error = assert_raises(ArgumentError) do
        diagram.add_class(@class1)
      end
      assert_match(/Class with name 'User' already exists/, error.message)
    end

    def test_add_relationship
      diagram = ClassDiagram.new(classes: [@class1, @class2])
      initial_checksum = diagram.checksum
      diagram.add_relationship(@rel1)

      assert_equal [@rel1], diagram.relationships
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_relationship_invalid_class
      diagram = ClassDiagram.new(classes: [@class1]) # Missing Order class
      error = assert_raises(ArgumentError) do
        diagram.add_relationship(@rel1)
      end
      assert_match(/Relationship refers to non-existent class names/, error.message)
    end

    def test_find_class
      diagram = ClassDiagram.new(classes: [@class1, @class2])

      assert_equal @class1, diagram.find_class('User')
      assert_nil diagram.find_class('InvalidClass')
    end

    def test_to_h_content
      diagram = ClassDiagram.new(classes: [@class1], relationships: [])
      expected = {
        classes: [@class1.to_h],
        relationships: []
      }

      assert_equal expected, diagram.to_h_content
    end

    def test_to_h
      diagram = ClassDiagram.new(classes: [@class1], relationships: [], version: 5)
      expected = {
        type: 'class_diagram',
        version: 5,
        checksum: diagram.checksum,
        data: {
          classes: [@class1.to_h],
          relationships: []
        }
      }

      assert_equal expected, diagram.to_h
    end

    def test_serialization_deserialization
      diagram1 = ClassDiagram.new(classes: [@class1, @class2], relationships: [@rel1], version: 'v3')
      json_data = diagram1.to_json
      diagram2 = Base.from_json(json_data) # Use Base factory

      assert_instance_of ClassDiagram, diagram2
      assert_equal diagram1.version, diagram2.version
      # Compare content via checksum (equality uses checksum)
      assert_equal diagram1, diagram2
      # Explicit content check
      assert_equal diagram1.classes.map(&:to_h), diagram2.classes.map(&:to_h)
      assert_equal diagram1.relationships.map(&:to_h), diagram2.relationships.map(&:to_h)
    end

    def test_equality
      diagram1 = ClassDiagram.new(classes: [@class1], relationships: [])
      diagram2 = ClassDiagram.new(
        classes: [Elements::ClassEntity.new(name: 'User', attributes: ['id: Integer', 'name: String'],
                                            methods: ['save()'])], relationships: []
      )
      diagram3 = ClassDiagram.new(classes: [@class1, @class2], relationships: [])
      diagram4 = ClassDiagram.new(classes: [@class1], relationships: [], version: 2) # Different version

      assert_equal diagram1, diagram2 # Same content
      refute_equal diagram1, diagram3 # Different content
      assert_equal diagram1, diagram4 # Same content, different version (equality ignores version)
    end
  end
end
