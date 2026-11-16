# frozen_string_literal: true

require 'test_helper'

# Regressions from the third review: each test failed before its fix, except
# the last, which pins the one deliberate difference from Mermaid.
class Round3Test < Minitest::Test
  # 1: the program records owned, frozen values, not the caller's strings.
  def test_caller_strings_cannot_rewrite_the_program
    git = Diagrams::GitgraphDiagram.new
    id = +'A'
    message = +'first'
    name = +'dev'
    tag = +'v1'
    git.commit(id:, message:, tags: [tag])
    git.branch(name:)
    git.commit(id: +'B')
    git.checkout(name: +'main')
    git.merge(branch: name, id: +'M')
    before = [git.to_json, JSON.generate(git.statements)]
    [id, message, name, tag].each { it.replace('changed') }

    assert_equal before, [git.to_json, JSON.generate(git.statements)]
    assert_raises(FrozenError) { git.statements.first[:message].replace('x') }
    assert_raises(FrozenError) { git.statements.first[:tags] << 'x' }
  end

  def test_no_diagram_keeps_a_caller_string
    label = +'Start'
    title = +'Flow'
    version = +'v1'
    flow = Diagrams::FlowchartDiagram.new(title:, version:)
    flow.add_node(id: 'a', label:)
    before = flow.to_json
    [label, title, version].each { it.replace('changed') }

    assert_equal before, flow.to_json
  end

  def test_string_subclasses_are_copied_to_plain_strings
    sneaky = Class.new(String)

    assert_instance_of String, Diagrams::Elements::Node.new(id: sneaky.new('a'), label: 'A').id
  end

  # 3: every integer that reaches Mermaid is one JavaScript holds exactly.
  def test_branch_order_beyond_two_to_the_53_is_refused
    git = Diagrams::GitgraphDiagram.new

    assert_equal 2**53, git.branch(name: 'a', order: 2**53).order
    assert_error(RangeError, /order must be between 0 and 2\*\*53/) { git.branch(name: 'b', order: (2**53) + 1) }
  end

  # 4: dates are proleptic Gregorian, as JavaScript's.
  def test_gantt_dates_are_proleptic_gregorian
    gantt = Diagrams::GanttDiagram.new
    gantt.add_task(id: 'reform', label: 'R', start: '1582-10-10', duration: '1d')

    assert_error(ArgumentError, /start "1500-02-29" is not a form/) do
      gantt.add_task(id: 'leap', label: 'L', start: '1500-02-29', duration: '1d')
    end
    assert_equal Time.utc(1582, 10, 10)...Time.utc(1582, 10, 11), gantt.schedule['reform']
  end

  # 5: ids that every JavaScript object already has break Mermaid's lookup.
  def test_gantt_ids_that_are_javascript_object_names_are_refused
    %w[__proto__ constructor hasOwnProperty toString valueOf prototype].each do |id|
      assert_error(ArgumentError, /is a JavaScript object property/) do
        Diagrams::Elements::Task.new(id:, label: 'T', start: '2026-01-01', duration: '1d')
      end
    end
  end

  # 6: a task is placed as Mermaid places it, or refused.
  def test_gantt_schedule_follows_mermaid
    gantt = Diagrams::GanttDiagram.new
    gantt.add_task(id: 'a', label: 'A', start: '2026-01-31', duration: '1M')
    gantt.add_task(id: 'b', label: 'B', start: 'after a', duration: '1.5d')
    gantt.add_task(id: 'c', label: 'C', start: '2024-02-29', duration: '1y')
    gantt.add_task(id: 'd', label: 'D', start: 'after a b', duration: '90m')
    gantt.add_task(id: 'e', label: 'E', start: '2026-01-01', duration: 'until b')

    assert_equal({ 'a' => [Time.utc(2026, 1, 31), Time.utc(2026, 2, 28)],
                   'b' => [Time.utc(2026, 2, 28), Time.utc(2026, 3, 2)],
                   'c' => [Time.utc(2024, 2, 29), Time.utc(2025, 2, 28)],
                   'd' => [Time.utc(2026, 3, 2), Time.utc(2026, 3, 2, 1, 30)],
                   'e' => [Time.utc(2026, 1, 1), Time.utc(2026, 2, 28)] },
                 gantt.schedule.transform_values { [it.begin, it.end] })
  end

  def test_gantt_lengths_beyond_mermaids_dates_are_refused
    gantt = Diagrams::GanttDiagram.new

    ['999999999999999d', "#{'9' * 400}d", '8000y', '120000M'].each do |duration|
      assert_error(ArgumentError, /falls outside years 0100-9999|beyond Mermaid's dates/) do
        gantt.add_task(id: 't', label: 'T', start: '2026-01-01', duration:)
      end
    end
    assert_empty gantt.tasks
  end

  # 7: the one deliberate difference from Mermaid's gitGraph.
  def test_duplicate_commit_ids_are_refused
    git = Diagrams::GitgraphDiagram.new
    git.commit(id: 'A')

    assert_error(ArgumentError, /Commit "A" already exists/) { git.commit(id: 'A') }
  end
end
