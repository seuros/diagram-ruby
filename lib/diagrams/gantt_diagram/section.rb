# frozen_string_literal: true

module Diagrams
  class GanttDiagram
    class Section < Dry::Struct
      attribute :name, GanttDiagram::Types::String
      attribute :tasks, GanttDiagram::Types::Array.of(Task)

      def to_json(*_args)
        {
          name:,
          tasks: tasks.map(&:to_json)
        }
      end
    end
  end
end
