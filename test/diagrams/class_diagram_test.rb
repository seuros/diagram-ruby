# frozen_string_literal: true

require 'test_helper'

class ClassDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::ClassDiagram.new
    @diagram.add_class(name: 'Animal', attributes: ['+String name'], operations: ['+speak() String'])
    @diagram.add_class(name: 'Dog')
  end

  def test_classes
    animal = @diagram.classes.first

    assert_equal ['+String name'], animal.attributes
    assert_equal ['+speak() String'], animal.operations
    assert_empty @diagram.classes.last.operations
  end

  def test_relationships
    relationship = @diagram.add_relationship(source_class_name: 'Animal', target_class_name: 'Dog',
                                             type: 'inheritance', label: 'is a')

    assert_equal :inheritance, relationship.type
  end

  def test_relationships_need_both_classes
    assert_error(ArgumentError, /no class "Cat"/) do
      @diagram.add_relationship(source_class_name: 'Cat', target_class_name: 'Dog', type: :association)
    end
  end

  def test_duplicate_classes_are_rejected
    assert_error(ArgumentError, /ClassEntity "Dog" already exists/) { @diagram.add_class(name: 'Dog') }
  end

  def test_round_trip
    @diagram.add_relationship(source_class_name: 'Animal', target_class_name: 'Dog', type: :inheritance)

    assert_round_trip(@diagram)
  end
end
