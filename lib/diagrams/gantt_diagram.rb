# frozen_string_literal: true

module Diagrams
  class GanttDiagram < AbstractDiagram
    attribute :title, GanttDiagram::Types::String
    attribute :sections, GanttDiagram::Types::Array.of(Section)

    def type
      'gantt'
    end

    def to_json(*_args)
      {
        title:,
        sections: sections.map(&:to_json)
      }
    end
  end
end
