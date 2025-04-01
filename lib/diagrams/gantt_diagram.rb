# frozen_string_literal: true

module Diagrams
  # Represents a Gantt Chart diagram consisting of tasks over time, grouped into sections.
  class GanttDiagram < Base
    DEFAULT_SECTION_TITLE = 'Default Section'

    attr_reader :title, :sections

    # Initializes a new GanttDiagram.
    #
    # @param title [String] The title of the Gantt chart.
    # @param sections [Array<Element::GanttSection>] An array of section objects (containing tasks).
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(title: '', sections: [], version: 1)
      super(version:)
      @title = title.is_a?(String) ? title : ''
      @sections = sections.is_a?(Array) ? sections : []
      ensure_default_section if @sections.empty?
      validate_elements!
      update_checksum!
    end

    # Adds a new section to the diagram.
    # Subsequent tasks will be added to this section.
    #
    # @param section_title [String] The title of the section.
    # @raise [ArgumentError] if a section with the same title already exists.
    # @return [Elements::GanttSection] The newly added section.
    def add_section(section_title)
      clean_title = section_title.strip
      raise ArgumentError, "Section title '#{clean_title}' cannot be empty" if clean_title.empty?
      raise ArgumentError, "Section with title '#{clean_title}' already exists" if find_section(clean_title)

      # Remove default section if it's empty and we're adding a real one
      if @sections.size == 1 && @sections.first.title == DEFAULT_SECTION_TITLE && @sections.first.tasks.empty? # Check tasks for GanttSection
        @sections.clear
      end

      # Use GanttSection
      new_section = Elements::GanttSection.new(title: clean_title, tasks: [])
      @sections << new_section
      update_checksum!
      new_section
    end

    # Adds a task to the current (last) section of the diagram.
    #
    # @param id [String] Unique ID for the task (used for dependencies).
    # @param label [String] Display name/label for the task.
    # @param status [Symbol, nil] Status (:done, :active, :crit). nil implies default/future.
    # @param start [String] Start date, task ID (e.g., 'task1'), or dependency string ('after taskX').
    # @param duration [String] Duration string (e.g., '7d', '2w').
    # @raise [ArgumentError] if required fields are missing or a task with the same ID exists.
    # @raise [StandardError] if no sections exist.
    # @return [Elements::Task] The added task.
    def add_task(id:, label:, start:, duration:, status: nil)
      raise ArgumentError, 'Task ID cannot be empty' if id.nil? || id.strip.empty?
      raise ArgumentError, "Task with ID '#{id}' already exists" if find_task(id)

      new_task = Elements::Task.new(
        id:,
        label:,
        status:,
        start:,
        duration:
      )

      current_section = @sections.last
      raise StandardError, 'Cannot add task: No section available.' unless current_section

      # Add task to the current section's 'tasks' array
      updated_tasks = current_section.tasks + [new_task]
      updated_section = Elements::GanttSection.new(title: current_section.title, tasks: updated_tasks)

      # Update the section in the main array
      current_section_index = @sections.index { |s| s.title == current_section.title }
      unless current_section_index
        raise StandardError,
              "Could not find index for current section '#{current_section.title}'"
      end

      @sections[current_section_index] = updated_section

      update_checksum!
      new_task
    end

    # Finds a task by its ID across all sections.
    #
    # @param task_id [String] The ID of the task to find.
    # @return [Element::Task, nil] The found task or nil.
    def find_task(task_id)
      all_tasks.find { |t| t.id == task_id }
    end

    # Finds a section by its title.
    # @param section_title [String] The title of the section.
    # @return [Elements::GanttSection, nil] The found section or nil.
    def find_section(section_title)
      @sections.find { |s| s.title == section_title }
    end

    # Returns the specific content of the Gantt diagram as a hash.
    #
    # @return [Hash{Symbol => String | Array<Hash>}]
    def to_h_content
      {
        title: @title,
        # Serialize sections, renaming 'periods' back to 'tasks' for clarity
        sections: @sections.map(&:to_h) # Use GanttSection's to_h directly
      }
    end

    # Returns a hash mapping element types to their collections for diffing.
    #
    # @return [Hash{Symbol => Array<Diagrams::Elements::Task>}]
    def identifiable_elements
      {
        # Diffing based on tasks directly might be more useful than sections here
        tasks: all_tasks
        # sections: @sections # Could also diff sections if needed
      }
    end

    # Class method to create a GanttDiagram from a hash.
    #
    # @param data_hash [Hash] Hash containing `:title` and `:sections` array.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional, for verification).
    # @return [GanttDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      title = data_hash[:title] || data_hash['title'] || ''
      sections_data = data_hash[:sections] || data_hash['sections'] || []

      sections = sections_data.map do |section_h|
        section_data = section_h.transform_keys(&:to_sym)
        tasks_data = section_data[:tasks] || [] # Expect 'tasks' key in hash
        # Map task data to Task objects
        tasks = tasks_data.map do |task_h|
          task_data = task_h.transform_keys(&:to_sym)
          # Convert status back to symbol if it's a string and present
          task_data[:status] = task_data[:status].to_sym if task_data[:status].is_a?(String)
          Elements::Task.new(task_data)
        end
        Elements::GanttSection.new(title: section_data[:title], tasks: tasks)
      end

      diagram = new(title:, sections:, version:)

      # Optional: Verify checksum
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded GanttDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
      end

      diagram
    end

    private

    # Helper to get all tasks from all sections.
    def all_tasks
      @sections.flat_map(&:tasks)
    end

    # Ensures a default section exists if the sections array is empty.
    def ensure_default_section
      return if @sections.any? { |s| s.title == DEFAULT_SECTION_TITLE }

      @sections << Elements::GanttSection.new(title: DEFAULT_SECTION_TITLE, tasks: [])
    end

    # Validates the consistency of tasks during initialization.
    def validate_elements!
      task_ids = all_tasks.map(&:id)
      return if task_ids.uniq.size == all_tasks.size

      raise ArgumentError, 'Duplicate task IDs found'
      # Add more validation if needed (e.g., date formats, dependencies)
    end

    # Protected method access
    protected :update_checksum!
  end
end
