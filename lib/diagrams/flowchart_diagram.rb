# frozen_string_literal: true

module Diagrams
  class FlowchartDiagram < AbstractDiagram
    attribute :id, Types::String
    attribute :nodes, Types::Array.of(Node)
    attribute :links, Types::Array.of(Link)

    def type
      'flowchart'
    end

    def to_json(*_args)
      {
        id:,
        nodes: nodes.map(&:to_json),
        links: links.map(&:to_json)
      }
    end
  end
end
