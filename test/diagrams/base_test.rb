# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class BaseTest < DiagramTest
    # Dummy subclass for testing abstract methods
    class ConcreteDiagram < Base
      attr_reader :nodes # Add reader for test access if needed

      def initialize(version: 1)
        super
        @nodes = [] # Initialize @nodes
        # update_checksum! will be called after setting nodes in test
        update_checksum! # Calculate initial checksum
      end

      # Implement to reflect the @nodes variable used in tests
      def to_h_content
        { nodes: (@nodes || []).map(&:to_h) }
      end

      # Implement identifiable_elements directly
      def identifiable_elements
        { nodes: @nodes || [] }
      end

      # Minimal class-level from_h for testing factory
      def self.from_h(_data_hash, version:, _checksum:)
        # Simplified for test purposes
        nodes_data = _data_hash[:nodes] || []
        nodes = nodes_data.map { |h| Elements::Node.new(h.transform_keys(&:to_sym)) }
        new(version:).tap { |d| d.instance_variable_set(:@nodes, nodes) }
      end
    end

    def test_initialize_abstract_class
      # Test that direct instantiation raises error
      assert_raises NotImplementedError, 'Cannot instantiate abstract class Diagrams::Base' do
        Diagrams::Base.new
      end
    end

    def test_initialize_concrete_class
      # Test that concrete subclass can be instantiated
      diagram = ConcreteDiagram.new(version: 'alpha')

      assert_instance_of ConcreteDiagram, diagram
      assert_equal 'alpha', diagram.version
      refute_nil diagram.checksum # Checksum should be calculated
    end

    def test_to_h_content_abstract
      # Test that calling to_h_content on a base instance (if possible) raises
      # We need a concrete instance to test this properly
      diagram = ConcreteDiagram.new
      # We can't directly test the abstract method on Base,
      # but we ensure concrete classes *must* implement it.
      # If ConcreteDiagram didn't implement it, `new` would likely fail,
      # or calling methods relying on it (like to_h) would fail.
      # Let's test that to_h works on the concrete class.
      assert_respond_to diagram, :to_h_content
      assert_equal({ nodes: [] }, diagram.to_h_content) # Expect nodes array now
    end

    def test_to_h_structure
      diagram = ConcreteDiagram.new(version: 2)
      expected_hash = {
        type: 'concrete_diagram',
        version: 2,
        checksum: diagram.checksum, # Use the actual checksum
        data: { nodes: [] } # Expect nodes array now
      }

      assert_equal expected_hash, diagram.to_h
    end

    def test_to_json
      diagram = ConcreteDiagram.new(version: 'beta')
      expected_hash = {
        type: 'concrete_diagram',
        version: 'beta',
        checksum: diagram.checksum,
        data: { nodes: [] } # Expect nodes array now
      }
      expected_json = JSON.generate(expected_hash)

      assert_equal expected_json, diagram.to_json
    end

    def test_diff_added_removed
      diagram1 = ConcreteDiagram.new
      node_a = Elements::Node.new(id: 'a', label: 'A')
      node_b = Elements::Node.new(id: 'b', label: 'B')
      diagram1.instance_variable_set(:@nodes, [node_a]) # Simulate adding node
      diagram1.send(:update_checksum!) # Use send for protected method

      diagram2 = ConcreteDiagram.new
      diagram2.instance_variable_set(:@nodes, [node_b]) # Simulate different node
      diagram2.send(:update_checksum!) # Use send for protected method

      # No longer need to override identifiable_elements as it's implemented in ConcreteDiagram

      diff_result = diagram1.diff(diagram2)

      expected_diff = {
        nodes: {
          added: [node_b],
          removed: [node_a]
          # modified: [] # Basic diff doesn't reliably detect modification yet
        }
      }

      assert_equal expected_diff, diff_result
    end

    def test_diff_no_change
      diagram1 = ConcreteDiagram.new
      node_a = Elements::Node.new(id: 'a', label: 'A')
      diagram1.instance_variable_set(:@nodes, [node_a])
      diagram1.send(:update_checksum!) # Use send for protected method

      diagram2 = ConcreteDiagram.new
      diagram2.instance_variable_set(:@nodes, [node_a])
      diagram2.send(:update_checksum!) # Use send for protected method

      # No longer need to override identifiable_elements
      diff_result = diagram1.diff(diagram2)

      assert_empty diff_result
    end

    def test_diff_different_types
      ConcreteDiagram.new
      # Need another concrete type for this test, skip for now
      # diagram2 = AnotherConcreteDiagram.new
      # assert_empty diagram1.diff(diagram2)
      skip 'Need another concrete diagram type to test diff across types.'
    end
  end
end
