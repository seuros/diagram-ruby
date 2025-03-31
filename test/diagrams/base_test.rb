# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class BaseTest < DiagramTest
    # Dummy subclass for testing abstract methods
    class ConcreteDiagram < Base
      def initialize(version: 1)
        super
        # No content needed for these tests
        update_checksum! # Calculate initial checksum based on empty content
      end

      def to_h_content
        {} # Minimal implementation for testing base class
      end

      # Minimal class-level from_h for testing factory
      def self.from_h(_data_hash, version:, checksum:)
        new(version:) # Ignore data/checksum for this test
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
      assert_empty(diagram.to_h_content) # Based on our dummy implementation
    end

    def test_to_h_structure
      diagram = ConcreteDiagram.new(version: 2)
      expected_hash = {
        type: 'ConcreteDiagram',
        version: 2,
        checksum: diagram.checksum, # Use the actual checksum
        data: {}
      }

      assert_equal expected_hash, diagram.to_h
    end

    def test_to_json
      diagram = ConcreteDiagram.new(version: 'beta')
      expected_hash = {
        type: 'ConcreteDiagram',
        version: 'beta',
        checksum: diagram.checksum,
        data: {}
      }
      expected_json = JSON.generate(expected_hash)

      assert_equal expected_json, diagram.to_json
    end

    # Add tests for equality, checksum updates, and deserialization factory later
    # when we have more concrete diagram types to work with.
  end
end
