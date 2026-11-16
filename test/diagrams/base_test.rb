# frozen_string_literal: true

require 'test_helper'

class BaseTest < Minitest::Test
  def flowchart(title: nil)
    Diagrams::FlowchartDiagram.new(title:).tap do |diagram|
      diagram.add_node(id: 'A', label: 'Start')
      diagram.add_node(id: 'B', label: 'End')
      diagram.add_edge(source_id: 'A', target_id: 'B')
    end
  end

  def test_base_is_abstract
    assert_raises(NotImplementedError) { Diagrams::Base.new }
  end

  def test_type_names
    assert_equal 'flowchart_diagram', Diagrams::FlowchartDiagram.type
    assert_equal 'er_diagram', Diagrams::ERDiagram.type
    assert_equal 'gitgraph_diagram', Diagrams::GitgraphDiagram.type
  end

  def test_title_is_checked
    assert_equal 'Flow', flowchart(title: 'Flow').title
    assert_error(TypeError, /title must be a String/) { Diagrams::PieDiagram.new(title: 1) }
    assert_error(ArgumentError, /title cannot be blank/) { Diagrams::PieDiagram.new(title: ' ') }
  end

  def test_to_h
    hash = flowchart(title: 'Flow').to_h

    assert_equal 'flowchart_diagram', hash[:type]
    assert_equal 1, hash[:version]
    assert_equal flowchart(title: 'Flow').checksum, hash[:checksum]
    assert_equal({ title: 'Flow', nodes: [{ id: 'A', label: 'Start' }, { id: 'B', label: 'End' }],
                   edges: [{ source_id: 'A', target_id: 'B' }] }, hash[:data])
  end

  def test_round_trip_keeps_version
    diagram = Diagrams::FlowchartDiagram.new(version: 'v2')

    assert_equal 'v2', assert_round_trip(diagram).version
  end

  def test_from_h_accepts_string_keys
    hash = JSON.parse(flowchart.to_json)

    assert_equal flowchart, Diagrams::Base.from_h(hash)
    assert_equal flowchart, Diagrams::FlowchartDiagram.from_h(hash)
  end

  def test_from_h_rejects_an_unknown_or_other_type
    assert_error(ArgumentError, /not a known diagram type: "sankey"/) { Diagrams::Base.from_h(type: 'sankey', data: {}) }
    assert_error(ArgumentError, /not a pie_diagram diagram type/) { Diagrams::PieDiagram.from_h(flowchart.to_h) }
  end

  def test_from_h_requires_data
    assert_error(ArgumentError, /no :data/) { Diagrams::Base.from_h(type: 'pie_diagram') }
  end

  def test_from_h_rejects_a_checksum_mismatch
    hash = flowchart.to_h.merge(checksum: 'bogus')

    assert_error(ArgumentError, /checksum mismatch/) { Diagrams::Base.from_h(hash) }
  end

  def test_from_h_checks_elements_like_add
    hash = flowchart.to_h.except(:checksum)
    hash[:data][:edges] << { source_id: 'A', target_id: 'Z' }

    assert_error(ArgumentError, /no node "Z"/) { Diagrams::Base.from_h(hash) }
  end

  def test_from_json_rejects_invalid_json
    assert_raises(JSON::ParserError) { Diagrams::Base.from_json('{') }
  end

  def test_equality_follows_type_and_content
    assert_equal flowchart, flowchart
    assert_equal flowchart.hash, flowchart.hash
    assert flowchart.eql?(flowchart)
    refute_equal flowchart, flowchart(title: 'Other')
    refute_equal Diagrams::StateDiagram.new, Diagrams::FlowchartDiagram.new
  end

  def test_checksum_follows_content_not_version
    assert_equal flowchart.checksum, Diagrams::FlowchartDiagram.from_h(flowchart.to_h.merge(version: 9)).checksum
    refute_equal flowchart.checksum, flowchart(title: 'T').checksum
  end

  def test_collections_are_frozen
    diagram = flowchart

    assert_predicate diagram.nodes, :frozen?
    assert_raises(FrozenError) { diagram.nodes << diagram.nodes.first }
  end

  def test_duplicate_keys_are_rejected
    assert_error(ArgumentError, /Node "A" already exists/) { flowchart.add_node(id: 'A', label: 'Again') }
  end

  def test_diff_reports_added_removed_and_modified
    old = flowchart
    new = Diagrams::FlowchartDiagram.new
    new.add_node(id: 'A', label: 'Begin')
    new.add_node(id: 'C', label: 'Other')
    new.add_edge(source_id: 'A', target_id: 'C')

    diff = old.diff(new)

    assert_equal [{ old: old.nodes[0], new: new.nodes[0] }], diff[:nodes][:modified]
    assert_equal [new.nodes[1]], diff[:nodes][:added]
    assert_equal [old.nodes[1]], diff[:nodes][:removed]
    assert_equal({ added: new.edges, removed: old.edges }, diff[:edges])
  end

  def test_diff_of_empty_diagrams_is_empty
    assert_empty Diagrams::FlowchartDiagram.new.diff(Diagrams::FlowchartDiagram.new)
  end

  def test_diff_of_equal_diagrams_is_empty
    assert_empty flowchart.diff(flowchart)
  end

  def test_diff_needs_the_same_type
    assert_raises(TypeError) { flowchart.diff(Diagrams::StateDiagram.new) }
  end
end
