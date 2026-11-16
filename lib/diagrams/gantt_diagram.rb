# frozen_string_literal: true

module Diagrams
  # Tasks over time, grouped in sections (see Sectioned).
  class GanttDiagram < Base
    include Sectioned

    collection :sections, add: :add_section

    # +tasks+ are Task values or hashes of their members.
    def add_section(title: nil, tasks: [])
      open_section(Elements::GanttSection, :tasks, title, Check.elements(tasks, :tasks, Elements::Task))
    end

    def add_task(id:, label:, start:, duration:, status: nil)
      add_to_section(Elements::GanttSection, :tasks, Elements::Task.new(id:, label:, start:, duration:, status:))
    end

    def tasks = sections.flat_map(&:tasks)
  end
end
