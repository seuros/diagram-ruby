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

    assert_error(ArgumentError, /"dev" and "main" are both at "A"/) { git.merge(branch: 'dev') }
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
    assert_raises(TypeError) { Diagrams::Elements::Task.new(id: 't', label: 'T', start: '2026-01-01', duration: '1d', status: false) }
    task = Diagrams::Elements::Task.new(id: 't', label: 'T', start: '2026-01-01', duration: '1d')
    assert_raises(TypeError) { task.with(status: false) }
    git = Diagrams::GitgraphDiagram.new
    assert_raises(TypeError) { git.commit(id: false) }
    git.commit(id: 'A')
    assert_raises(TypeError) { git.branch(name: 'x', order: false) }
    assert_raises(TypeError) { git.checkout(name: false) }
    git.branch(name: 'dev')
    git.commit(id: 'D')
    git.checkout(name: 'main')
    assert_raises(TypeError) { git.merge(branch: 'dev', id: false) }
  end

  # 11: malformed input raises TypeError (wrong container or key type) or
  # ArgumentError (missing part), never NoMethodError.
  def test_malformed_loads
    [nil, [], 'x', { 17 => 'x' }, { type: 'state_diagram', data: nil },
     { type: 'state_diagram', data: { states: nil } }, { type: 'state_diagram', data: { states: ['idle'] } },
     { type: 'state_diagram', data: { states: [{ 1 => 'idle' }] } },
     { type: 'gitgraph_diagram', data: { statements: [nil] } }].each do |input|
      assert_raises(TypeError, input.inspect) { Diagrams::Base.from_h(input) }
    end
    assert_raises(ArgumentError) { Diagrams::Base.from_h(type: 'state_diagram') }
  end

  # 12 (round 2): Marshal would rebuild values without their checks, and old
  # native records load without any hook, so Marshal is refused outright.
  def test_marshal_is_refused
    flow = Diagrams::FlowchartDiagram.new
    attribute = Diagrams::Elements::ERDAttribute.new(type: 'int', name: 'id')

    assert_error(TypeError, /FlowchartDiagram cannot be marshalled; use to_h and from_h/) { Marshal.dump(flow) }
    assert_error(TypeError, /ERDAttribute cannot be marshalled/) { Marshal.dump(attribute) }
  end

  # Round 2: version is a String, Integer or nil, which round-trip unchanged.
  def test_version_domain
    %w[v1].push(3, nil).each do |version|
      diagram = Diagrams::PieDiagram.new(version:)

      assert_equal [version], [Diagrams::Base.from_json(diagram.to_json).version]
    end
    [:v1, { 'major' => 1 }, 1.5].each do |version|
      assert_raises(TypeError) { Diagrams::PieDiagram.new(version:) }
    end
  end

  # Round 2: integers a JSON number (an IEEE double) cannot hold exactly.
  def test_integers_beyond_two_to_the_53_are_refused
    assert_equal 2**53, Diagrams::Elements::Slice.new(label: 'x', value: 2**53).value
    [(2**53) + 1, 10**400].each do |value|
      assert_error(RangeError, /at most 2\*\*53/) { Diagrams::Elements::Slice.new(label: 'x', value:) }
    end
  end

  # Round 2: Gantt tasks take the forms Mermaid evaluates.
  def test_gantt_tasks_take_mermaid_forms
    task = ->(**override) { Diagrams::Elements::Task.new(id: 't', label: 'T', start: '2026-01-01', duration: '1d', **override) }

    assert_error(ArgumentError, /id must be a word/) { task.call(id: 'a b') }
    %w[done active crit milestone vert].each do |id|
      assert_error(ArgumentError, /is a Mermaid task tag/) { task.call(id:) }
    end
    ['not-a-date', ' 2026-01-01', '2026-02-30', 'active', 'after done'].each do |start|
      assert_error(ArgumentError, /start .* is not a form Mermaid evaluates/) { task.call(start:) }
    end
    ['bad', '1d ', '1d:2d', '0x'].each do |duration|
      assert_error(ArgumentError, /duration .* is not a form Mermaid evaluates/) { task.call(duration:) }
    end
    assert_equal %w[a b c], task.call(start: 'after a b', duration: 'until c').references
    assert task.call(duration: '2026-02-01') && task.call(duration: '1.5h') && task.call(duration: '250ms')
  end

  def test_gantt_dependencies_name_earlier_tasks
    gantt = Diagrams::GanttDiagram.new
    gantt.add_task(id: 'a', label: 'A', start: '2026-01-01', duration: '1d')

    assert_error(ArgumentError, /refers to unknown tasks b/) do
      gantt.add_task(id: 'c', label: 'C', start: 'after a b', duration: '1d')
    end
    assert_error(ArgumentError, /refers to unknown tasks z/) do
      gantt.add_section(title: 'S', tasks: [{ id: 'y', label: 'Y', start: 'after z', duration: '1d' },
                                            { id: 'z', label: 'Z', start: 'after a', duration: '1d' }])
    end
    gantt.add_section(title: 'S', tasks: [{ id: 'z', label: 'Z', start: 'after a', duration: '1d' },
                                          { id: 'y', label: 'Y', start: 'after z', duration: 'until a' }])

    assert_equal %w[a z y], gantt.tasks.map(&:id)
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
