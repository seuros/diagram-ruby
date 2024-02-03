# frozen_string_literal: true

module Diagrams
  class GanttDiagram
    class Section < Dry::Struct
      attribute :name, GanttDiagram::Types::String
      attribute :tasks, GanttDiagram::Types::Array.of(Task)
    end
  end
end
