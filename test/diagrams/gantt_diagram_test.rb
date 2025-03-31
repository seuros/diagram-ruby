# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class GanttDiagramTest < DiagramTest
    def setup
      @task1 = Elements::Task.new(id: 't1', name: 'Planning', start_date: '2024-01-01', end_date: '2024-01-05')
      @task2 = Elements::Task.new(id: 't2', name: 'Development', start_date: '2024-01-06', end_date: '2024-01-15')
      @task3 = Elements::Task.new(id: 't3', name: 'Testing', start_date: '2024-01-16', end_date: '2024-01-20')
    end

    def test_initialize_empty
      diagram = GanttDiagram.new

      assert_equal '', diagram.title
      assert_empty diagram.tasks
      assert_equal 1, diagram.version
      refute_nil diagram.checksum
    end

    def test_initialize_with_elements
      diagram = GanttDiagram.new(title: 'Project Alpha', tasks: [@task1, @task2], version: 'beta')

      assert_equal 'Project Alpha', diagram.title
      assert_equal [@task1, @task2], diagram.tasks
      assert_equal 'beta', diagram.version
    end

    def test_initialize_validates_duplicate_task_id
      error = assert_raises(ArgumentError) do
        GanttDiagram.new(tasks: [@task1, @task1])
      end
      assert_match(/Duplicate task IDs found/, error.message)
    end

    def test_add_task
      diagram = GanttDiagram.new
      initial_checksum = diagram.checksum
      diagram.add_task(@task1)

      assert_equal [@task1], diagram.tasks
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_task_duplicate_id
      diagram = GanttDiagram.new(tasks: [@task1])
      error = assert_raises(ArgumentError) do
        diagram.add_task(@task1)
      end
      assert_match(/Task with ID 't1' already exists/, error.message)
    end

    def test_find_task
      diagram = GanttDiagram.new(tasks: [@task1, @task2])

      assert_equal @task1, diagram.find_task('t1')
      assert_nil diagram.find_task('t_invalid')
    end

    def test_to_h_content
      diagram = GanttDiagram.new(title: 'Simple Plan', tasks: [@task1])
      expected = {
        title: 'Simple Plan',
        tasks: [@task1.to_h]
      }

      assert_equal expected, diagram.to_h_content
    end

    def test_to_h
      diagram = GanttDiagram.new(title: 'Plan v4', tasks: [@task1], version: 4)
      expected = {
        type: 'GanttDiagram',
        version: 4,
        checksum: diagram.checksum,
        data: {
          title: 'Plan v4',
          tasks: [@task1.to_h]
        }
      }

      assert_equal expected, diagram.to_h
    end

    def test_serialization_deserialization
      diagram1 = GanttDiagram.new(title: 'Release Plan', tasks: [@task1, @task2], version: 'v1.1')
      json_data = diagram1.to_json
      diagram2 = Base.from_json(json_data) # Use Base factory

      assert_instance_of GanttDiagram, diagram2
      assert_equal diagram1.version, diagram2.version
      assert_equal diagram1.title, diagram2.title
      # Compare content via checksum (equality uses checksum)
      assert_equal diagram1, diagram2
      # Explicit content check
      assert_equal diagram1.tasks.map(&:to_h), diagram2.tasks.map(&:to_h)
    end

    def test_equality
      diagram1 = GanttDiagram.new(tasks: [@task1])
      diagram2 = GanttDiagram.new(tasks: [Elements::Task.new(id: 't1', name: 'Planning', start_date: '2024-01-01',
                                                             end_date: '2024-01-05')])
      diagram3 = GanttDiagram.new(tasks: [@task1, @task2])
      diagram4 = GanttDiagram.new(tasks: [@task1], version: 2) # Different version
      diagram5 = GanttDiagram.new(title: 'Different Title', tasks: [@task1]) # Different title

      assert_equal diagram1, diagram2 # Same content
      refute_equal diagram1, diagram3 # Different tasks
      assert_equal diagram1, diagram4 # Same content, different version
      refute_equal diagram1, diagram5 # Different title
    end
  end
end
