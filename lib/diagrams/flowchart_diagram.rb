# frozen_string_literal: true

module Diagrams
  # Nodes and the directed edges between them.
  class FlowchartDiagram < Base
    collection :nodes, add: :add_node
    collection :edges, add: :add_edge

    def add_node(id:, label:) = append(:nodes, Elements::Node.new(id:, label:))

    def add_edge(source_id:, target_id:, label: nil)
      edge = Elements::Edge.new(source_id:, target_id:, label:)
      find!(:nodes, edge.source_id, 'node')
      find!(:nodes, edge.target_id, 'node')
      append(:edges, edge)
    end
  end
end
