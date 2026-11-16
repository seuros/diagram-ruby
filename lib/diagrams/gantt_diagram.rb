# frozen_string_literal: true

module Diagrams
  # Tasks over time, grouped in sections (see Sectioned). A task's after and
  # until clauses name tasks added before it.
  class GanttDiagram < Base
    include Sectioned

    collection :sections, add: :add_section

    # +tasks+ are Task values or hashes of their members.
    def add_section(title: nil, tasks: [])
      tasks = Check.elements(tasks, :tasks, Elements::Task)
      tasks.each_with_index { |task, index| refuse_unknown_references(task, tasks.first(index)) }
      open_section(Elements::GanttSection, :tasks, title, tasks)
    end

    def add_task(id:, label:, start:, duration:, status: nil)
      task = Elements::Task.new(id:, label:, start:, duration:, status:)
      refuse_unknown_references(task)
      add_to_section(Elements::GanttSection, :tasks, task)
    end

    def tasks = sections.flat_map(&:tasks)

    private

    def refuse_unknown_references(task, pending = [])
      known = [*tasks, *pending].map(&:id)
      unknown = task.references - known
      raise ArgumentError, "task #{task.id.inspect} refers to unknown tasks #{unknown.join(', ')}" if unknown.any?
    end
  end
end
