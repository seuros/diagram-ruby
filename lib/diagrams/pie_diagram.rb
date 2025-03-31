# frozen_string_literal: true

require_relative 'base'
require_relative 'elements/slice'

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
      super(version:)
      @title = title.is_a?(String) ? title : ''
      @slices = slices.is_a?(Array) ? slices : []
      validate_elements!
      update_checksum!
    end

    # Adds a slice to the diagram.
    #
    # @param slice [Element::Slice] The slice object to add.
    # @raise [ArgumentError] if a slice with the same label already exists or if adding the slice exceeds 100%.
    # @return [Element::Slice] The added slice.
    def add_slice(slice)
      raise ArgumentError, 'Slice must be a Diagrams::Elements::Slice' unless slice.is_a?(Diagrams::Elements::Slice)
      raise ArgumentError, "Slice with label '#{slice.label}' already exists" if find_slice(slice.label)
      if (current_total + slice.value) > 100.0 + Float::EPSILON # Allow for minor float inaccuracies
        raise ArgumentError, "Adding slice '#{slice.label}' with value #{slice.value} exceeds 100%"
      end

      @slices << slice
      update_checksum!
      slice
    end

    # Finds a slice by its label.
    #
    # @param label [String] The label of the slice to find.
    # @return [Element::Slice, nil] The found slice or nil.
    def find_slice(label)
      @slices.find { |s| s.label == label }
    end

    # Calculates the current total percentage of all slices.
    # @return [Float]
    def current_total
      @slices.sum(&:value)
    end

    # Returns the specific content of the pie diagram as a hash.
    # Called by `Diagrams::Base#to_h`.
    #
    # @return [Hash{Symbol => String | Array<Hash>}]
    def to_h_content
      {
        title: @title,
        slices: @slices.map(&:to_h)
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

      slices = slices_data.map { |slice_h| Diagrams::Elements::Slice.new(slice_h.transform_keys(&:to_sym)) }

      diagram = new(title:, slices:, version:)

      # Optional: Verify checksum if provided
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded PieDiagram (version: #{version}). Expected #{checksum}, got #{diagram.checksum}."
        # Or raise an error: raise "Checksum mismatch..."
      end

      diagram
    end

    private

    # Validates the consistency of slices during initialization.
    def validate_elements!
      labels = @slices.map(&:label)
      raise ArgumentError, 'Duplicate slice labels found' unless labels.uniq.size == @slices.size

      total = current_total
      return unless total > 100.0 + Float::EPSILON # Allow for minor float inaccuracies

      raise ArgumentError, "Initial slice values exceed 100% (total: #{total}%)"
    end
  end
end
