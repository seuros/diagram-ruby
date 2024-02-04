# frozen_string_literal: true

module Diagrams
  class GanttDiagram
    class Section < Dry::Struct
      attribute :id, GanttDiagram::Types::String
      attribute :name, GanttDiagram::Types::String
      attribute :tasks, GanttDiagram::Types::Array.of(Task)

      def to_json(*_args)
        {
          id:,
          name:,
          tasks: tasks.map(&:to_json)
        }
      end
    end
  end
end
