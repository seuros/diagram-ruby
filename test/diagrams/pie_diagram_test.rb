# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class PieDiagramTest < DiagramTest
    def setup
      @slice1 = Elements::Slice.new(label: 'Apples', value: 30.0)
      @slice2 = Elements::Slice.new(label: 'Oranges', value: 45.5)
      @slice3 = Elements::Slice.new(label: 'Bananas', value: 24.5)
    end

    def test_initialize_empty
      diagram = PieDiagram.new

      assert_equal '', diagram.title
      assert_empty diagram.slices
      assert_equal 1, diagram.version
      refute_nil diagram.checksum
    end

    def test_initialize_with_elements
      diagram = PieDiagram.new(title: 'Fruit Sales', slices: [@slice1, @slice2], version: 'alpha')

      assert_equal 'Fruit Sales', diagram.title
      assert_equal [@slice1, @slice2], diagram.slices
      assert_equal 'alpha', diagram.version
      assert_in_delta 75.5, diagram.current_total # Check total calculation
    end

    def test_initialize_validates_duplicate_label
      error = assert_raises(ArgumentError) do
        PieDiagram.new(slices: [@slice1, @slice1])
      end
      assert_match(/Duplicate slice labels found/, error.message)
    end

    def test_initialize_validates_total_exceeds_100
      slice_too_big = Elements::Slice.new(label: 'Pears', value: 50.0)
      error = assert_raises(ArgumentError) do
        PieDiagram.new(slices: [@slice1, @slice2, slice_too_big]) # 30 + 45.5 + 50 > 100
      end
      assert_match(/Initial slice values exceed 100%/, error.message)
    end

    def test_add_slice
      diagram = PieDiagram.new(title: 'Inventory')
      initial_checksum = diagram.checksum
      diagram.add_slice(@slice1)

      assert_equal [@slice1], diagram.slices
      refute_equal initial_checksum, diagram.checksum
      assert_in_delta 30.0, diagram.current_total
    end

    def test_add_slice_duplicate_label
      diagram = PieDiagram.new(slices: [@slice1])
      error = assert_raises(ArgumentError) do
        diagram.add_slice(@slice1)
      end
      assert_match(/Slice with label 'Apples' already exists/, error.message)
    end

    # Renamed method
    def test_add_slice_exceeds_hundred
      diagram = PieDiagram.new(slices: [@slice1, @slice2]) # Total 75.5
      slice_too_big = Elements::Slice.new(label: 'Grapes', value: 30.0) # 75.5 + 30 > 100
      error = assert_raises(ArgumentError) do
        diagram.add_slice(slice_too_big)
      end
      assert_match(/exceeds 100%/, error.message)
    end

    def test_find_slice
      diagram = PieDiagram.new(slices: [@slice1, @slice2])

      assert_equal @slice1, diagram.find_slice('Apples')
      assert_nil diagram.find_slice('Pears')
    end

    def test_to_h_content
      diagram = PieDiagram.new(title: 'Simple Pie', slices: [@slice1])
      expected = {
        title: 'Simple Pie',
        slices: [@slice1.to_h]
      }

      assert_equal expected, diagram.to_h_content
    end

    def test_to_h
      diagram = PieDiagram.new(title: 'Pie v7', slices: [@slice1], version: 7)
      expected = {
        type: 'PieDiagram',
        version: 7,
        checksum: diagram.checksum,
        data: {
          title: 'Pie v7',
          slices: [@slice1.to_h]
        }
      }

      assert_equal expected, diagram.to_h
    end

    def test_serialization_deserialization
      diagram1 = PieDiagram.new(title: 'Market Share', slices: [@slice1, @slice2], version: 'v1.0')
      json_data = diagram1.to_json
      diagram2 = Base.from_json(json_data) # Use Base factory

      assert_instance_of PieDiagram, diagram2
      assert_equal diagram1.version, diagram2.version
      assert_equal diagram1.title, diagram2.title
      # Compare content via checksum (equality uses checksum)
      assert_equal diagram1, diagram2
      # Explicit content check
      assert_equal diagram1.slices.map(&:to_h), diagram2.slices.map(&:to_h)
    end

    def test_equality
      diagram1 = PieDiagram.new(slices: [@slice1])
      diagram2 = PieDiagram.new(slices: [Elements::Slice.new(label: 'Apples', value: 30.0)])
      diagram3 = PieDiagram.new(slices: [@slice1, @slice2])
      diagram4 = PieDiagram.new(slices: [@slice1], version: 2) # Different version
      diagram5 = PieDiagram.new(title: 'Different Title', slices: [@slice1]) # Different title

      assert_equal diagram1, diagram2 # Same content
      refute_equal diagram1, diagram3 # Different slices
      assert_equal diagram1, diagram4 # Same content, different version
      refute_equal diagram1, diagram5 # Different title
    end
  end
end
