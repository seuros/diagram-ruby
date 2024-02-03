# frozen_string_literal: true

module Diagrams
  class GanttDiagram < AbstractDiagram
    attribute :title, GanttDiagram::Types::String
    attribute :sections, GanttDiagram::Types::Array.of(Section)
  end
end
