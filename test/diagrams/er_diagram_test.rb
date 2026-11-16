# frozen_string_literal: true

require 'test_helper'

class ERDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::ERDiagram.new
    @diagram.add_entity(name: 'CUSTOMER', attributes: [
                          { type: 'int', name: 'id', keys: [:PK] },
                          Diagrams::Elements::ERDAttribute.new(type: 'string', name: 'email', keys: [:UK],
                                                               comment: 'login')
                        ])
    @diagram.add_entity(name: 'ORDER')
  end

  def test_entities
    customer = @diagram.entities.first

    assert_equal %w[id email], customer.attributes.map(&:name)
    assert_equal 'login', customer.attributes.last.comment
  end

  def test_relationships
    relationship = @diagram.add_relationship(entity1: 'CUSTOMER', entity2: 'ORDER', cardinality1: :ONE_ONLY,
                                             cardinality2: :ZERO_OR_MORE, identifying: true, label: 'places')

    assert relationship.identifying
    assert_equal :ZERO_OR_MORE, relationship.cardinality2
  end

  def test_relationships_need_both_entities
    assert_error(ArgumentError, /no entity "ITEM"/) do
      @diagram.add_relationship(entity1: 'ORDER', entity2: 'ITEM', cardinality1: :ONE_ONLY, cardinality2: :ONE_ONLY)
    end
  end

  def test_duplicate_entities_are_rejected
    assert_error(ArgumentError, /ERDEntity "ORDER" already exists/) { @diagram.add_entity(name: 'ORDER') }
  end

  def test_round_trip
    @diagram.add_relationship(entity1: 'CUSTOMER', entity2: 'ORDER', cardinality1: 'ONE_ONLY',
                              cardinality2: 'ONE_OR_MORE', label: 'places')

    assert_round_trip(@diagram)
  end
end
