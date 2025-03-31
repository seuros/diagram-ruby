# frozen_string_literal: true

module Diagrams
  # Represents a flowchart diagram consisting of nodes and edges connecting them.
  class FlowchartDiagram < Base
    attr_reader :nodes, :edges

    # Initializes a new FlowchartDiagram.
    #
    # @param nodes [Array<Element::Node>] An array of node objects.
    # @param edges [Array<Element::Edge>] An array of edge objects.
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(nodes: [], edges: [], version: 1)
      super(version:)
      @nodes = nodes.is_a?(Array) ? nodes : []
      @edges = edges.is_a?(Array) ? edges : []
      validate_elements!
      update_checksum!
    end

    # Adds a node to the diagram.
    #
    # @param node [Element::Node] The node object to add.
    # @raise [ArgumentError] if a node with the same ID already exists.
    # @return [Element::Node] The added node.
    def add_node(node)
      raise ArgumentError, 'Node must be a Diagrams::Element::Node' unless node.is_a?(Diagrams::Elements::Node)
      raise ArgumentError, "Node with ID '#{node.id}' already exists" if find_node(node.id)

      @nodes << node
      update_checksum!
      node
    end

    # Adds an edge to the diagram.
    #
    # @param edge [Element::Edge] The edge object to add.
    # @raise [ArgumentError] if the edge refers to non-existent node IDs.
    # @return [Element::Edge] The added edge.
    def add_edge(edge)
      raise ArgumentError, 'Edge must be a Diagrams::Element::Edge' unless edge.is_a?(Diagrams::Elements::Edge)
      unless find_node(edge.source_id) && find_node(edge.target_id)
        raise ArgumentError, "Edge refers to non-existent node IDs ('#{edge.source_id}' or '#{edge.target_id}')"
      end

      @edges << edge
      update_checksum!
      edge
    end

    # Finds a node by its ID.
    #
    # @param node_id [String] The ID of the node to find.
    # @return [Element::Node, nil] The found node or nil.
    def find_node(node_id)
      @nodes.find { |n| n.id == node_id }
    end

    # Returns the specific content of the flowchart diagram as a hash.
    # Called by `Diagrams::Base#to_h`.
    #
    # @return [Hash{Symbol => Array<Hash>}]
    def to_h_content
      {
        nodes: @nodes.map(&:to_h),
        edges: @edges.map(&:to_h)
      }
    end

    # Returns a hash mapping element types to their collections for diffing.
    # @see Diagrams::Base#identifiable_elements
    # @return [Hash{Symbol => Array<Diagrams::Elements::Node | Diagrams::Elements::Edge>}]
    def identifiable_elements
      {
        nodes: @nodes,
        edges: @edges
      }
    end

    # Class method to create a FlowchartDiagram from a hash.
    # Used by the deserialization factory in `Diagrams::Base`.
    #
    # @param data_hash [Hash] Hash containing `:nodes` and `:edges` arrays.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional, for verification).
    # @return [FlowchartDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      nodes_data = data_hash[:nodes] || data_hash['nodes'] || []
      edges_data = data_hash[:edges] || data_hash['edges'] || []

      nodes =
        nodes_data.map do |node_h|
          Diagrams::Elements::Node.new(node_h.transform_keys(&:to_sym))
        end
      edges =
        edges_data.map do |edge_h|
          Diagrams::Elements::Edge.new(edge_h.transform_keys(&:to_sym))
        end
      diagram = new(nodes:, edges:, version:)

      # Optional: Verify checksum if provided
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded FlowchartDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
        # Or raise an error: raise "Checksum mismatch..."
      end

      diagram
    end

    private

    # Validates the consistency of nodes and edges during initialization.
    def validate_elements!
      node_ids = @nodes.map(&:id)
      raise ArgumentError, 'Duplicate node IDs found' unless node_ids.uniq.size == @nodes.size

      @edges.each do |edge|
        unless node_ids.include?(edge.source_id) && node_ids.include?(edge.target_id)
          raise ArgumentError, "Edge refers to non-existent node IDs ('#{edge.source_id}' or '#{edge.target_id}')"
        end
      end
    end
  end
end
