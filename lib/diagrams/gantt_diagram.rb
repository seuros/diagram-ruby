# frozen_string_literal: true

module Diagrams
  # Tasks over time, grouped in sections (see Sectioned). A task's after and
  # until clauses name tasks added before it. Each task is placed as Mermaid
  # places it (see Calendar), and #schedule gives the result; a task Mermaid
  # could not place exactly is refused.
  class GanttDiagram < Base
    include Sectioned

    collection :sections, add: :add_section

    def initialize(**)
      super
      @times = {}.freeze
    end

    # +tasks+ are Task values or hashes of their members.
    def add_section(title: nil, tasks: [])
      tasks = Check.elements(tasks, :tasks, Elements::Task)
      times = tasks.reduce(@times) { |known, task| known.merge(task.id => place(task, known)) }
      open_section(Elements::GanttSection, :tasks, title, tasks).tap { @times = times.freeze }
    end

    def add_task(id:, label:, start:, duration:, status: nil)
      task = Elements::Task.new(id:, label:, start:, duration:, status:)
      time = place(task, @times)
      add_to_section(Elements::GanttSection, :tasks, task).tap { @times = @times.merge(task.id => time).freeze }
    end

    def tasks = sections.flat_map(&:tasks)

    # Task id => start...finish, as UTC Times, in Mermaid's evaluation.
    def schedule = @times.transform_values { |from, to| Calendar.to_time(from)...Calendar.to_time(to) }

    private

    # [start, finish] in UTC milliseconds.
    def place(task, known)
      unknown = task.references - known.keys
      raise ArgumentError, "task #{task.id.inspect} refers to unknown tasks #{unknown.join(', ')}" if unknown.any?

      start = moment(task.start, known) { |times| times.map(&:last).max }
      finish = moment(task.duration, known, start) { |times| times.map(&:first).min }
      [Calendar.check(start, "task #{task.id.inspect} start"), Calendar.check(finish, "task #{task.id.inspect} end")]
    end

    # A date, an after/until clause (resolved by the block), or a length.
    def moment(text, known, from = nil)
      return yield(text.split.drop(1).map { known.fetch(it) }) if text.match?(Elements::Task::CLAUSE)
      return Calendar.date(text) if text.match?(Elements::Task::DATE)

      Calendar.add(from, text)
    end
  end
end
