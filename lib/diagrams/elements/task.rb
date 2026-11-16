# frozen_string_literal: true

require 'date'

module Diagrams
  module Elements
    # A Gantt task, in the forms Mermaid's gantt evaluates:
    # - +start+: a date (YYYY-MM-DD) or "after <id> [<id> ...]";
    # - +duration+: a length (a number and ms, s, m, h, d, w, M or y), an end
    #   date, or "until <id> [<id> ...]";
    # - +id+: a word Mermaid does not read as a task tag;
    # - +status+: one of Mermaid's task tags.
    # GanttDiagram checks that the ids named by after/until exist.
    Task = Data.define(:id, :label, :start, :duration, :status) do
      include Element

      def initialize(id:, label:, start:, duration:, status: nil)
        super(
          id: Task.identifier(id),
          label: Check.string(label, :label),
          start: Task.syntax(Check.string(start, :start), :start, 'after', Task::DATE),
          duration: Task.syntax(Check.string(duration, :duration), :duration, 'until', Task::DATE, Task::LENGTH),
          status: status.nil? ? nil : Check.symbol(status, :status, Task::STATUSES)
        )
      end

      def key = id

      # The task ids an after/until clause names.
      def references = [start, duration].flat_map { it[Task::CLAUSE, 1]&.split || [] }

      class << self
        def identifier(id)
          id = Check.string(id, :id)
          unless id.match?(Task::WORD)
            raise ArgumentError, "id must be a word (letters, digits, _ and -), got #{id.inspect}"
          end
          raise ArgumentError, "id #{id.inspect} is a Mermaid task tag" if Task::TAGS.include?(id)

          id
        end

        def syntax(value, name, clause, *forms)
          if value.match?(/\A#{clause} #{Task::WORD_SOURCE}(?: #{Task::WORD_SOURCE})*\z/) && clause_ids_ok?(value)
            return value
          end
          return value if forms.include?(Task::DATE) && date?(value)
          return value if forms.include?(Task::LENGTH) && value.match?(Task::LENGTH)

          raise ArgumentError, "#{name} #{value.inspect} is not a form Mermaid evaluates"
        end

        def date?(value) = value.match?(Task::DATE) && Date.valid_date?(*value.split('-').map(&:to_i))

        def clause_ids_ok?(value) = value.split.drop(1).none? { Task::TAGS.include?(it) }
      end
    end

    Task::STATUSES = %i[done active crit milestone].freeze
    # Words Mermaid's gantt reads as task tags wherever a task's data starts.
    Task::TAGS = %w[active done crit milestone vert].freeze
    Task::WORD_SOURCE = '[A-Za-z0-9_-]+'
    Task::WORD = /\A#{Task::WORD_SOURCE}\z/
    Task::DATE = /\A\d{4}-\d{2}-\d{2}\z/
    Task::LENGTH = /\A\d+(?:\.\d+)?(?:ms|[Mdhmswy])\z/
    Task::CLAUSE = /\A(?:after|until) (.+)\z/
  end
end
