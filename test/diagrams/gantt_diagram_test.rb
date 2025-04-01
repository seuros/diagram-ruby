# frozen_string_literal: true

require 'test_helper'

module Diagrams
  # Changed from DiagramTest
  class GanttDiagramTest < Minitest::Test
    def setup
      # Define tasks using the new structure
      @task1_data = { id: 't1', label: 'Planning', start: '2024-01-01', duration: '5d', status: :done }
      @task2_data = { id: 't2', label: 'Development', start: 'after t1', duration: '10d', status: :active }
      @task3_data = { id: 't3', label: 'Testing', start: 'after t2', duration: '7d' } # Default status (future)
      @task4_data = { id: 't4', label: 'Deployment', start: 'after t3', duration: '3d', status: :crit }
    end

    def test_initialize_empty
      diagram = GanttDiagram.new

      assert_equal '', diagram.title
      assert_equal 1, diagram.sections.size # Should have default section
      assert_equal GanttDiagram::DEFAULT_SECTION_TITLE, diagram.sections.first.title
      assert_empty diagram.sections.first.tasks # Check tasks attribute
      assert_equal 1, diagram.version
      refute_nil diagram.checksum
    end

    def test_initialize_with_sections_and_tasks
      # NOTE: Initialization with sections/tasks directly is complex due to structure reuse.
      # It's generally easier to use add_section and add_task.
      # This test primarily checks the structure if initialized manually.
      task1 = Elements::Task.new(@task1_data)
      task2 = Elements::Task.new(@task2_data)
      section1 = Elements::GanttSection.new(title: 'Phase 1', tasks: [task1]) # Use GanttSection
      section2 = Elements::GanttSection.new(title: 'Phase 2', tasks: [task2]) # Use GanttSection
      diagram = GanttDiagram.new(title: 'Project Alpha', sections: [section1, section2], version: 'beta')

      assert_equal 'Project Alpha', diagram.title
      assert_equal 2, diagram.sections.size
      assert_equal section1, diagram.sections[0]
      assert_equal section2, diagram.sections[1]
      assert_equal [task1], diagram.sections[0].tasks # Check tasks attribute
      assert_equal [task2], diagram.sections[1].tasks # Check tasks attribute
      assert_equal 'beta', diagram.version
    end

    def test_add_section
      diagram = GanttDiagram.new
      initial_checksum = diagram.checksum
      section = diagram.add_section('Planning')

      assert_equal 1, diagram.sections.size # Default removed
      assert_equal 'Planning', section.title
      assert_equal section, diagram.sections.last
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_task_to_default_section
      diagram = GanttDiagram.new
      initial_checksum = diagram.checksum
      task = diagram.add_task(**@task1_data)

      assert_equal 1, diagram.sections.size
      default_section = diagram.sections.first

      assert_equal GanttDiagram::DEFAULT_SECTION_TITLE, default_section.title
      assert_equal [task], default_section.tasks # Tasks are in 'tasks'
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_task_to_custom_section
      diagram = GanttDiagram.new
      diagram.add_section('Development')
      task = diagram.add_task(**@task2_data)

      assert_equal 1, diagram.sections.size
      custom_section = diagram.sections.first

      assert_equal 'Development', custom_section.title
      assert_equal [task], custom_section.tasks
    end

    def test_add_task_duplicate_id
      diagram = GanttDiagram.new
      diagram.add_task(**@task1_data)
      error = assert_raises(ArgumentError) do
        diagram.add_task(**@task1_data) # Same ID
      end
      assert_match(/Task with ID 't1' already exists/, error.message)
    end

    def test_find_task
      diagram = GanttDiagram.new
      diagram.add_section('Phase 1')
      diagram.add_task(**@task1_data)
      diagram.add_section('Phase 2')
      diagram.add_task(**@task2_data)

      assert_equal 'Planning', diagram.find_task('t1').label
      assert_equal 'Development', diagram.find_task('t2').label
      assert_nil diagram.find_task('t_invalid')
    end

    def test_to_h_content
      diagram = GanttDiagram.new(title: 'Simple Plan')
      diagram.add_section('All Tasks')
      task1 = diagram.add_task(**@task1_data)
      task2 = diagram.add_task(**@task2_data)

      expected = {
        title: 'Simple Plan',
        sections: [
          { title: 'All Tasks', tasks: [task1.to_h, task2.to_h] }
        ]
      }

      assert_equal expected, diagram.to_h_content
    end

    def test_to_h
      diagram = GanttDiagram.new(title: 'Plan v4', version: 4)
      diagram.add_section('Core')
      task1 = diagram.add_task(**@task1_data)
      expected_data = {
        title: 'Plan v4',
        sections: [{ title: 'Core', tasks: [task1.to_h] }]
      }
      expected_full = {
        type: 'gantt_diagram',
        version: 4,
        checksum: diagram.checksum, # Get checksum after adding task
        data: expected_data
      }

      assert_equal expected_full, diagram.to_h
    end

    def test_serialization_deserialization
      diagram1 = GanttDiagram.new(title: 'Release Plan', version: 'v1.1')
      diagram1.add_section('Prep')
      diagram1.add_task(**@task1_data)
      diagram1.add_section('Exec')
      diagram1.add_task(**@task2_data)
      diagram1.add_task(**@task3_data)

      diagram1.checksum
      json_data = diagram1.to_json
      diagram2 = Base.from_json(json_data) # Use Base factory

      assert_instance_of GanttDiagram, diagram2
      assert_equal diagram1.version, diagram2.version
      assert_equal diagram1.title, diagram2.title
      assert_equal diagram1.sections.size, diagram2.sections.size
      assert_equal diagram1, diagram2 # Equality uses checksum

      # Explicit content check
      assert_equal diagram1.sections[0].title, diagram2.sections[0].title
      assert_equal diagram1.sections[0].tasks.map(&:to_h), diagram2.sections[0].tasks.map(&:to_h) # Compare tasks
      assert_equal diagram1.sections[1].title, diagram2.sections[1].title
      assert_equal diagram1.sections[1].tasks.map(&:to_h), diagram2.sections[1].tasks.map(&:to_h)
    end

    def test_equality
      # Equality is based on checksum, which depends on content (title, sections, tasks)
      diagram1 = GanttDiagram.new
      diagram1.add_section('S1')
      diagram1.add_task(**@task1_data)

      diagram2 = GanttDiagram.new
      diagram2.add_section('S1')
      diagram2.add_task(**@task1_data) # Same content

      diagram3 = GanttDiagram.new
      diagram3.add_section('S1')
      diagram3.add_task(**@task2_data) # Different task

      diagram4 = GanttDiagram.new(version: 2) # Different version, same content
      diagram4.add_section('S1')
      diagram4.add_task(**@task1_data)

      diagram5 = GanttDiagram.new(title: 'Different') # Different title
      diagram5.add_section('S1')
      diagram5.add_task(**@task1_data)

      assert_equal diagram1, diagram2
      refute_equal diagram1, diagram3
      assert_equal diagram1, diagram4 # Equality ignores version if content matches
      refute_equal diagram1, diagram5
    end

    # TODO: Add diff tests for GanttDiagram
  end
end
