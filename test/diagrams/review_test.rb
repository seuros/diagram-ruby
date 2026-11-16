# frozen_string_literal: true

require 'test_helper'

# Regressions from the 0.4.0 review: each test failed before its fix.
class ReviewTest < Minitest::Test
  # 6: Mermaid refuses a merge of two branches with the same head.
  def test_merge_of_identical_heads_is_refused_without_change
    git = Diagrams::GitgraphDiagram.new
    git.commit(id: 'A')
    git.branch(name: 'dev')
    git.checkout(name: 'main')
    before = git.to_h

    assert_error(ArgumentError, /"dev" and "main" are both at "A"/) { git.merge(from_branch_name: 'dev') }
    assert_equal before, git.to_h
  end

  # 7: only Integer and finite Float, the numbers JSON round-trips.
  def test_numbers_outside_integer_and_float_are_type_errors
    [Rational(1, 2), Complex(1, 1), 1r].each do |value|
      assert_error(TypeError, /value must be an Integer or Float, got (Rational|Complex)/) do
        Diagrams::Elements::Slice.new(label: 'x', value:)
      end
    end
  end

  def test_big_decimal_is_a_type_error
    big_decimal = Class.new(Numeric) { def finite? = true }.new

    assert_raises(TypeError) { Diagrams::Elements::Slice.new(label: 'x', value: big_decimal) }
  end

  # 8: percentages are exact; a total beyond Float is refused.
  def test_percentages_do_not_overflow
    pie = Diagrams::PieDiagram.new
    pie.add_slice(label: 'a', value: 1e307)

    assert_equal({ 'a' => 100.0 }, pie.percentages)
    pie.add_slice(label: 'b', value: 3e307)

    assert_equal({ 'a' => 25.0, 'b' => 75.0 }, pie.percentages)
  end

  def test_a_total_beyond_float_is_refused_without_change
    pie = Diagrams::PieDiagram.new
    pie.add_slice(label: 'a', value: 1e308)

    assert_error(RangeError, /total of the slices must stay finite/) { pie.add_slice(label: 'b', value: 1e308) }
    assert_equal 1, pie.slices.size
  end

  # 9: equality is strict, so equal diagrams hash equally.
  def test_equality_is_strict_and_agrees_with_hash
    one = Diagrams::PieDiagram.new.tap { it.add_slice(label: 'x', value: 1) }
    one_float = Diagrams::PieDiagram.new.tap { it.add_slice(label: 'x', value: 1.0) }
    same = Diagrams::PieDiagram.new.tap { it.add_slice(label: 'x', value: 1) }

    refute_equal one, one_float
    refute one.eql?(one_float)
    assert_equal one.hash, same.hash
    assert_equal(:found, { one => :found }[same])
    assert_equal({ slices: { modified: [{ old: one.slices.first, new: one_float.slices.first }] } },
                 one.diff(one_float))
  end

  # 10: false is a value of the wrong type, never "absent".
  def test_false_is_a_type_error
    assert_raises(TypeError) { Diagrams::Elements::Task.new(id: 't', label: 'T', start: 's', duration: 'd', status: false) }
    task = Diagrams::Elements::Task.new(id: 't', label: 'T', start: 's', duration: 'd')
    assert_raises(TypeError) { task.with(status: false) }
    git = Diagrams::GitgraphDiagram.new
    assert_raises(TypeError) { git.commit(id: false) }
    git.commit(id: 'A')
    assert_raises(TypeError) { git.branch(name: 'x', start_commit_id: false) }
    assert_raises(TypeError) { git.checkout(name: false) }
    git.branch(name: 'dev')
    git.commit(id: 'D')
    git.checkout(name: 'main')
    assert_raises(TypeError) { git.merge(from_branch_name: 'dev', id: false) }
  end

  # 11: malformed input raises TypeError (wrong container or key type) or
  # ArgumentError (missing part), never NoMethodError.
  def test_malformed_loads
    [nil, [], 'x', { 17 => 'x' }, { type: 'state_diagram', data: nil },
     { type: 'state_diagram', data: { states: nil } }, { type: 'state_diagram', data: { states: ['idle'] } },
     { type: 'state_diagram', data: { states: [{ 1 => 'idle' }] } },
     { type: 'gitgraph_diagram', data: { branches: [nil] } }].each do |input|
      assert_raises(TypeError, input.inspect) { Diagrams::Base.from_h(input) }
    end
    assert_raises(ArgumentError) { Diagrams::Base.from_h(type: 'state_diagram') }
  end

  # 12: Marshal goes through the checked path and yields frozen values.
  def test_marshal_rebuilds_elements_through_the_checks
    attribute = Marshal.load(Marshal.dump(Diagrams::Elements::ERDAttribute.new(type: 'int', name: 'id')))

    assert_predicate attribute.name, :frozen?
    assert_raises(FrozenError) { attribute.name.clear }
  end

  def test_marshal_rebuilds_diagrams
    flow = Diagrams::FlowchartDiagram.new(title: 'F', version: 3)
    flow.add_node(id: 'a', label: 'A')
    copy = Marshal.load(Marshal.dump(flow))

    assert_equal flow, copy
    assert_equal 3, copy.version
    assert_predicate copy.nodes.first.label, :frozen?
  end

  def test_nested_elements_are_rebuilt_not_trusted
    sneaky = Class.new(Diagrams::Elements::ERDAttribute) { def name = +'mutable' }
    entity = Diagrams::Elements::ERDEntity.new(name: 'T', attributes: [sneaky.new(type: 'int', name: 'id')])

    assert_instance_of Diagrams::Elements::ERDAttribute, entity.attributes.first
    assert_equal 'id', entity.attributes.first.name
  end

  # 13: diff keeps the multiplicity of elements without a key.
  def test_diff_counts_duplicate_unkeyed_elements
    one = Diagrams::FlowchartDiagram.new
    one.add_node(id: 'a', label: 'A')
    one.add_node(id: 'b', label: 'B')
    two = Diagrams::Base.from_h(one.to_h)
    one.add_edge(source_id: 'a', target_id: 'b')
    edge = nil
    2.times { edge = two.add_edge(source_id: 'a', target_id: 'b') }

    assert_equal({ edges: { added: [edge] } }, one.diff(two))
    assert_equal({ edges: { removed: [edge] } }, two.diff(one))
  end

  # A refused section leaves the diagram as it was.
  def test_a_refused_section_changes_nothing
    gantt = Diagrams::GanttDiagram.new
    gantt.add_task(id: 'x', label: 'X', start: '2026-01-01', duration: '1d')
    before = gantt.to_h

    assert_error(ArgumentError, /Task "x" already exists/) do
      gantt.add_section(title: 'Late', tasks: [{ id: 'x', label: 'X', start: '2026-01-01', duration: '1d' }])
    end
    assert_equal before, gantt.to_h
  end
end
