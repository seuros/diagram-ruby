# frozen_string_literal: true

module Diagrams
  class FlowchartDiagram < AbstractDiagram
    attribute :id, Types::String
    attribute :nodes, Types::Array.of(Node)
    attribute :links, Types::Array.of(Link)
  end
end
