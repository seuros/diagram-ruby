# frozen_string_literal: true

require 'test_helper'

class FlowchartDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::FlowchartDiagram.new
    @diagram.add_node(id: 'A', label: 'Start')
    @diagram.add_node(id: 'B', label: 'End')
  end

  def test_add_returns_the_element
    edge = @diagram.add_edge(source_id: 'A', target_id: 'B', label: 'go')

    assert_equal Diagrams::Elements::Edge.new(source_id: 'A', target_id: 'B', label: 'go'), edge
    assert_equal [edge], @diagram.edges
    assert_equal %w[A B], @diagram.nodes.map(&:id)
  end

  def test_edges_need_both_nodes
    assert_error(ArgumentError, /no node "Z"/) { @diagram.add_edge(source_id: 'A', target_id: 'Z') }
    assert_error(ArgumentError, /no node "Y"/) { @diagram.add_edge(source_id: 'Y', target_id: 'A') }
  end

  def test_parallel_edges_are_allowed
    2.times { @diagram.add_edge(source_id: 'A', target_id: 'B') }

    assert_equal 2, @diagram.edges.size
  end

  def test_round_trip
    @diagram.add_edge(source_id: 'A', target_id: 'B', label: 'go')

    assert_round_trip(@diagram)
  end
end
