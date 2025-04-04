# frozen_string_literal: true

module Diagrams
  # Represents a Pie Chart diagram consisting of slices.
  class PieDiagram < Base
    attr_reader :title, :slices

    # Initializes a new PieDiagram.
    #
    # @param title [String] The title of the pie chart.
    # @param slices [Array<Element::Slice>] An array of slice objects.
    # @param version [String, Integer, nil] User-defined version identifier.
    def initialize(title: '', slices: [], version: 1)
      super(version: version) # Corrected super call
      @title = title.is_a?(String) ? title : ''
      @slices = [] # Initialize empty
      # Add initial slices using the corrected add_slice method
      Array(slices).each { |s| add_slice(s, update_checksum: false, initial_load: true) }
      recalculate_percentages! # Calculate initial percentages
      update_checksum! # Calculate final checksum after initial load
    end

    # Adds a slice to the diagram.
    #
    # @param slice [Element::Slice] The slice object to add.
    # @raise [ArgumentError] if a slice with the same label already exists.
    # @return [Element::Slice] The added slice.
    # Added initial_load flag to skip checksum update during initialize loop
    def add_slice(slice, update_checksum: true, initial_load: false)
      raise ArgumentError, 'Slice must be a Diagrams::Elements::Slice' unless slice.is_a?(Diagrams::Elements::Slice)
      raise ArgumentError, "Slice with label '#{slice.label}' already exists" if find_slice(slice.label)

      # Store a new instance to hold the calculated percentage later
      # Ensure percentage is nil initially
      new_slice_instance = slice.class.new(slice.attributes.except(:percentage))
      @slices << new_slice_instance
      recalculate_percentages! # Update percentages for all slices
      update_checksum! if update_checksum && !initial_load # Avoid multiple checksums during init
      new_slice_instance # Return the instance added to the array
    end

    # Finds a slice by its label.
    #
    # @param label [String] The label of the slice to find.
    # @return [Element::Slice, nil] The found slice or nil.
    def find_slice(label)
      @slices.find { |s| s.label == label }
    end

    # Calculates the total raw value of all slices.
    # @return [Float]
    def total_value
      @slices.sum(&:value)
    end

    # Returns the specific content of the pie diagram as a hash.
    # Called by `Diagrams::Base#to_h`.
    #
    # @return [Hash{Symbol => String | Array<Hash>}]
    def to_h_content
      {
        title: @title,
        # Ensure slices include calculated percentage in their hash
        slices: @slices.map(&:to_h)
      }
    end

    # Returns a hash mapping element types to their collections for diffing.
    # @see Diagrams::Base#identifiable_elements
    # @return [Hash{Symbol => Array<Diagrams::Elements::Slice>}]
    def identifiable_elements
      {
        slices: @slices
      }
    end

    # Class method to create a PieDiagram from a hash.
    # Used by the deserialization factory in `Diagrams::Base`.
    #
    # @param data_hash [Hash] Hash containing `:title` and `:slices` array.
    # @param version [String, Integer, nil] Diagram version.
    # @param checksum [String, nil] Expected checksum (optional, for verification).
    # @return [PieDiagram] The instantiated diagram.
    def self.from_h(data_hash, version:, checksum:)
      title = data_hash[:title] || data_hash['title'] || ''
      slices_data = data_hash[:slices] || data_hash['slices'] || []

      # Initialize with raw values, percentage will be recalculated by `new` -> `add_slice` -> `recalculate_percentages!`
      slices = slices_data.map do |slice_h|
        Diagrams::Elements::Slice.new(slice_h.transform_keys(&:to_sym).except(:percentage))
      end

      diagram = new(title: title, slices: slices, version: version)

      # Optional: Verify checksum if provided AFTER initialization is complete
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded PieDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
        # Or raise an error: raise "Checksum mismatch..."
      end

      diagram
    end

    private

    # Recalculates the percentage for each slice based on the total value.
    # This method modifies the @slices array in place by replacing Slice instances.
    def recalculate_percentages!
      total = total_value
      new_slices = @slices.map do |slice|
        percentage = total.zero? ? 0.0 : (slice.value / total * 100.0).round(2)
        # Create a new instance with the calculated percentage
        slice.class.new(slice.attributes.merge(percentage: percentage))
      end
      # Replace the entire array to ensure changes are reflected
      @slices = new_slices
    end

    # Validates the consistency of slices during initialization.
    def validate_elements!
      labels = @slices.map(&:label)
      return if labels.uniq.size == @slices.size

      raise ArgumentError, 'Duplicate slice labels found'
    end
  end
end
