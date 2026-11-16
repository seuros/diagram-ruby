# frozen_string_literal: true

require 'test_helper'

class GanttDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::GanttDiagram.new(title: 'Launch')
  end

  def test_tasks_go_to_the_last_section
    @diagram.add_section(title: 'Design')
    @diagram.add_task(id: 'd1', label: 'Sketch', start: '2024-01-01', duration: '3d', status: :done)
    @diagram.add_section(title: 'Build', tasks: [{ id: 'b1', label: 'Code', start: 'after d1', duration: '1w' }])
    @diagram.add_task(id: 'b2', label: 'Test', start: 'after b1', duration: '2d', status: :crit)

    assert_equal([%w[d1], %w[b1 b2]], @diagram.sections.map { it.tasks.map(&:id) })
    assert_equal %w[d1 b1 b2], @diagram.tasks.map(&:id)
  end

  def test_a_task_before_any_section_opens_an_untitled_one
    @diagram.add_task(id: 't1', label: 'Kickoff', start: '2024-01-01', duration: '1d')

    assert_nil @diagram.sections.first.title
    assert_error(ArgumentError, /only the first section can be untitled/) { @diagram.add_section }
  end

  def test_task_ids_are_unique_across_sections
    @diagram.add_section(title: 'A', tasks: [{ id: 't1', label: 'x', start: '2024-01-01', duration: '1d' }])
    @diagram.add_section(title: 'B')

    assert_error(ArgumentError, /Task "t1" already exists/) do
      @diagram.add_task(id: 't1', label: 'y', start: '2024-01-02', duration: '1d')
    end
  end

  def test_section_titles_are_unique
    @diagram.add_section(title: 'A')

    assert_error(ArgumentError, /GanttSection "A" already exists/) { @diagram.add_section(title: 'A') }
  end

  def test_round_trip
    @diagram.add_task(id: 't0', label: 'Prep', start: '2024-01-01', duration: '1d')
    @diagram.add_section(title: 'Work', tasks: [{ id: 't1', label: 'Do', start: 'after t0', duration: '2d',
                                                  status: :active }])

    assert_round_trip(@diagram)
  end
end
