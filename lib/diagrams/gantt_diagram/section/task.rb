# frozen_string_literal: true

module Diagrams
  class GanttDiagram
    class Section
      class Task < Dry::Struct
        attribute :id, GanttDiagram::Types::String
        attribute :name, GanttDiagram::Types::String
        attribute :start, GanttDiagram::Types::String
        attribute :end, GanttDiagram::Types::String

        def to_json(*_args)
          {
            id:,
            name:,
            start:,
            end:
          }
        end
      end
    end
  end
end
