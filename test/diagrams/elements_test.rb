# frozen_string_literal: true

require 'test_helper'

class ElementsTest < Minitest::Test
  include Diagrams::Elements

  def test_wrong_type_is_a_type_error
    assert_error(TypeError, /id must be a String, got Integer/) { Node.new(id: 1, label: 'x') }
    assert_error(TypeError, /events must be an Array/) { TimelinePeriod.new(label: 'x', events: 'a') }
    assert_error(TypeError, /identifying must be true or false/) do
      ERDRelationship.new(entity1: 'A', entity2: 'B', cardinality1: :ONE_ONLY, cardinality2: :ONE_ONLY, identifying: 1)
    end
    assert_error(TypeError, /value must be an Integer or Float, got String/) { Slice.new(label: 'x', value: '1') }
    assert_error(TypeError, /status must be a Symbol/) { task(status: 1) }
  end

  def test_bad_value_is_an_argument_or_range_error
    assert_error(ArgumentError, /label cannot be blank/) { Node.new(id: 'A', label: ' ') }
    assert_error(ArgumentError, /status must be one of done, active, crit, milestone, got late/) { task(status: :late) }
    assert_error(ArgumentError, /type must be one of/) do
      Relationship.new(source_class_name: 'A', target_class_name: 'B', type: :friend)
    end
    assert_error(RangeError, /value must be finite and >= 0, got -1/) { Slice.new(label: 'x', value: -1) }
    assert_error(RangeError, /got NaN/) { Slice.new(label: 'x', value: Float::NAN) }
    assert_error(ArgumentError, /events cannot be empty/) { TimelinePeriod.new(label: 'x', events: []) }
  end

  def test_missing_or_unknown_members_are_argument_errors
    assert_raises(ArgumentError) { Node.new(id: 'A') }
    assert_raises(ArgumentError) { Node.new(id: 'A', label: 'x', color: 'red') }
  end

  def test_symbols_accept_their_string_names
    assert_equal :done, task(status: 'done').status
  end

  def test_elements_are_frozen_values
    node = Node.new(id: 'A', label: 'x')

    assert_predicate node, :frozen?
    assert_predicate node.id, :frozen?
    assert_equal node, Node.new(id: 'A', label: 'x')
    assert_equal node.hash, Node.new(id: 'A', label: 'x').hash
    assert_predicate ClassEntity.new(name: 'A', attributes: ['+id']).attributes, :frozen?
  end

  def test_with_checks_again
    assert_raises(TypeError) { Node.new(id: 'A', label: 'x').with(label: nil) }
  end

  def test_key_identifies_an_element
    assert_equal 'A', Node.new(id: 'A', label: 'x').key
    assert_nil Edge.new(source_id: 'A', target_id: 'B').key
  end

  def test_to_h_leaves_out_nil_and_nests
    entity = ERDEntity.new(name: 'User', attributes: [{ type: 'int', name: 'id', keys: %w[PK] }])

    assert_equal({ source_id: 'A', target_id: 'B' }, Edge.new(source_id: 'A', target_id: 'B').to_h)
    assert_equal({ name: 'User', attributes: [{ type: 'int', name: 'id', keys: [:PK] }] }, entity.to_h)
  end

  def test_from_h_takes_string_keys
    assert_equal Node.new(id: 'A', label: 'x'), Node.from_h('id' => 'A', 'label' => 'x')
  end

  def test_nested_elements_accept_values_or_hashes
    attribute = ERDAttribute.new(type: 'int', name: 'id')

    assert_equal ERDEntity.new(name: 'U', attributes: [attribute]),
                 ERDEntity.new(name: 'U', attributes: [attribute.to_h])
    assert_error(TypeError, /attributes must contain Diagrams::Elements::ERDAttribute or Hash/) do
      ERDEntity.new(name: 'U', attributes: ['id'])
    end
  end

  def test_erd_attribute_keys
    assert_equal %i[PK FK], ERDAttribute.new(type: 'int', name: 'id', keys: %w[PK FK PK]).keys
    assert_raises(ArgumentError) { ERDAttribute.new(type: 'int', name: 'id', keys: [:XK]) }
  end

  def test_erd_entity_rejects_duplicate_attributes
    assert_error(ArgumentError, /attribute "id" appears twice/) do
      ERDEntity.new(name: 'U', attributes: [{ type: 'int', name: 'id' }, { type: 'uuid', name: 'id' }])
    end
  end

  def test_git_branch_starts_without_head_or_order
    assert_equal [nil, nil], GitBranch.new(name: 'main').to_h.values_at(:order, :head_commit_id)
  end

  private

  def task(**) = Task.new(id: 't', label: 'T', start: '2024-01-01', duration: '1d', **)
end
