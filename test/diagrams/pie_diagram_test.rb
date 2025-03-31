# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class PieDiagramTest < DiagramTest
    # Using raw values now
    def setup
      @slice1_raw = Elements::Slice.new(label: 'Apples', value: 30)
      @slice2_raw = Elements::Slice.new(label: 'Oranges', value: 45)
      @slice3_raw = Elements::Slice.new(label: 'Bananas', value: 25) # Total raw = 100
    end

    def test_initialize_empty
      diagram = PieDiagram.new

      assert_equal '', diagram.title
      assert_empty diagram.slices
      assert_equal 1, diagram.version
      refute_nil diagram.checksum
    end

    def test_initialize_with_elements
      # Initialize with raw values
      diagram = PieDiagram.new(title: 'Fruit Sales', slices: [@slice1_raw, @slice2_raw], version: 'alpha')

      assert_equal 'Fruit Sales', diagram.title
      assert_equal 2, diagram.slices.size
      assert_equal 'alpha', diagram.version
      # Check calculated percentages (30 / 75 * 100 = 40.0, 45 / 75 * 100 = 60.0)
      assert_in_delta 40.0, diagram.slices[0].percentage
      assert_equal 'Apples', diagram.slices[0].label
      assert_in_delta 60.0, diagram.slices[1].percentage
      assert_equal 'Oranges', diagram.slices[1].label
      assert_in_delta 75.0, diagram.total_value # Check total raw value calculation
    end

    def test_initialize_validates_duplicate_label
      error = assert_raises(ArgumentError) do
        PieDiagram.new(slices: [@slice1_raw, @slice1_raw])
      end
      assert_match(/Slice with label 'Apples' already exists/, error.message)
    end

    def test_add_slice
      diagram = PieDiagram.new(title: 'Inventory')
      initial_checksum = diagram.checksum
      diagram.add_slice(@slice1_raw) # Add raw value slice

      # Check the slice added to the diagram
      added_slice_in_diagram = diagram.slices.first

      assert_equal 1, diagram.slices.size
      assert_equal 'Apples', added_slice_in_diagram.label
      assert_equal 30, added_slice_in_diagram.value # Raw value
      assert_in_delta 100.0, added_slice_in_diagram.percentage # Only slice, so 100%
      # assert_same added_slice, added_slice_in_diagram # This might fail due to recalculate_percentages! replacing the object
      refute_equal initial_checksum, diagram.checksum
      assert_in_delta 30.0, diagram.total_value
    end

    def test_add_slice_duplicate_label
      diagram = PieDiagram.new(slices: [@slice1_raw])
      error = assert_raises(ArgumentError) do
        diagram.add_slice(@slice1_raw)
      end
      assert_match(/Slice with label 'Apples' already exists/, error.message)
    end

    def test_find_slice
      diagram = PieDiagram.new(slices: [@slice1_raw, @slice2_raw])

      assert_equal 'Apples', diagram.find_slice('Apples').label # Compare attributes
      assert_nil diagram.find_slice('Pears')
    end

    def test_to_h_content
      diagram = PieDiagram.new(title: 'Simple Pie', slices: [@slice1_raw])
      # Expected hash should include calculated percentage
      expected_slice_hash = { label: 'Apples', value: 30.0, percentage: 100.0 }
      expected = {
        title: 'Simple Pie',
        slices: [expected_slice_hash]
      }

      assert_equal expected, diagram.to_h_content
    end

    def test_to_h
      diagram = PieDiagram.new(title: 'Pie v7', slices: [@slice1_raw], version: 7)
      expected_slice_hash = { label: 'Apples', value: 30.0, percentage: 100.0 }
      expected = {
        type: 'pie_diagram',
        version: 7,
        checksum: diagram.checksum,
        data: {
          title: 'Pie v7',
          slices: [expected_slice_hash]
        }
      }

      assert_equal expected, diagram.to_h
    end

    def test_serialization_deserialization
      diagram1 = PieDiagram.new(title: 'Market Share', slices: [@slice1_raw, @slice2_raw], version: 'v1.0')
      json_data = diagram1.to_json
      diagram2 = Base.from_json(json_data) # Use Base factory

      assert_instance_of PieDiagram, diagram2
      assert_equal diagram1.version, diagram2.version
      assert_equal diagram1.title, diagram2.title
      # Compare content via checksum (equality uses checksum)
      assert_equal diagram1, diagram2
      # Explicit content check (need to compare hashes as object identity changes)
      assert_equal diagram1.slices.map(&:to_h), diagram2.slices.map(&:to_h)
    end

    def test_equality
      diagram1 = PieDiagram.new(slices: [@slice1_raw])
      diagram2 = PieDiagram.new(slices: [Elements::Slice.new(label: 'Apples', value: 30)]) # Same raw value
      diagram3 = PieDiagram.new(slices: [@slice1_raw, @slice2_raw])
      diagram4 = PieDiagram.new(slices: [@slice1_raw], version: 2) # Different version
      diagram5 = PieDiagram.new(title: 'Different Title', slices: [@slice1_raw]) # Different title

      assert_equal diagram1, diagram2 # Same content
      refute_equal diagram1, diagram3 # Different slices
      assert_equal diagram1, diagram4 # Same content, different version
      refute_equal diagram1, diagram5 # Different title
    end

    def test_equality_different_slice_values
      diagram1 = PieDiagram.new(slices: [Elements::Slice.new(label: 'A', value: 50)]) # Raw value 50
      diagram2 = PieDiagram.new(slices: [Elements::Slice.new(label: 'A', value: 60)]) # Raw value 60

      refute_equal diagram1, diagram2
      refute_equal diagram1.checksum, diagram2.checksum
    end
  end
end
