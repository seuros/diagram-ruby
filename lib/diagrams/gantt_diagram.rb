# frozen_string_literal: true

module Diagrams
  # Represents a Gantt Chart diagram consisting of tasks over time.
  class GanttDiagram < Base
    attr_reader :title, :tasks

    # Initializes a new GanttDiagram.
    #
    # @param title [String] The title of the Gantt chart.
    # @param tasks [Array<Element::Task>] An array of task objects.
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(title: '', tasks: [], version: 1)
      super(version:)
      @title = title.is_a?(String) ? title : ''
      @tasks = tasks.is_a?(Array) ? tasks : []
      validate_elements!
      update_checksum!
    end

    # Adds a task to the diagram.
    #
    # @param task [Element::Task] The task object to add.
    # @raise [ArgumentError] if a task with the same ID already exists.
    # @return [Element::Task] The added task.
    def add_task(task)
      raise ArgumentError, 'Task must be a Diagrams::Elements::Task' unless task.is_a?(Diagrams::Elements::Task)
      raise ArgumentError, "Task with ID '#{task.id}' already exists" if find_task(task.id)

      @tasks << task
      update_checksum!
      task
    end

    # Finds a task by its ID.
    #
    # @param task_id [String] The ID of the task to find.
    # @return [Element::Task, nil] The found task or nil.
    def find_task(task_id)
      @tasks.find { |t| t.id == task_id }
    end

    # Returns the specific content of the Gantt diagram as a hash.
    # Called by `Diagrams::Base#to_h`.
    #
    # @return [Hash{Symbol => String | Array<Hash>}]
    def to_h_content
      {
        title: @title,
        tasks: @tasks.map(&:to_h)
      }
    end

    # Returns a hash mapping element types to their collections for diffing.
    # @see Diagrams::Base#identifiable_elements
    # @return [Hash{Symbol => Array<Diagrams::Elements::Task>}]
    def identifiable_elements
      {
        tasks: @tasks
      }
    end

    # Class method to create a GanttDiagram from a hash.
    # Used by the deserialization factory in `Diagrams::Base`.
    #
    # @param data_hash [Hash] Hash containing `:title` and `:tasks` array.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional, for verification).
    # @return [GanttDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      title = data_hash[:title] || data_hash['title'] || ''
      tasks_data = data_hash[:tasks] || data_hash['tasks'] || []

      tasks = tasks_data.map { |task_h| Diagrams::Elements::Task.new(task_h.transform_keys(&:to_sym)) }

      diagram = new(title:, tasks:, version:)

      # Optional: Verify checksum if provided
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded GanttDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
        # Or raise an error: raise "Checksum mismatch..."
      end

      diagram
    end

    private

    # Validates the consistency of tasks during initialization.
    def validate_elements!
      task_ids = @tasks.map(&:id)
      return if task_ids.uniq.size == @tasks.size

      raise ArgumentError, 'Duplicate task IDs found'

      # Add more validation if needed (e.g., date formats, dependencies)
    end
  end
end
