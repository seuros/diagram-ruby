# frozen_string_literal: true

module Diagrams
  # Abstract base class for all diagram types.
  # Provides common functionality like versioning, checksum calculation,
  # serialization, and equality comparison.
  class Base
    # Provides `==`, `eql?`, and `hash` methods based on specified attributes.
    # Diagrams are equal if they are of the same class and have the same content (checksum).
    include Dry::Equalizer(:class, :checksum)

    attr_reader :version, :checksum

    # Initializes the base diagram attributes.
    # Subclasses should call super.
    #
    # @param version [String, Integer, nil] User-defined version identifier. Defaults to 1.
    def initialize(version: 1)
      # Prevent direct instantiation of the base class
      raise NotImplementedError, 'Cannot instantiate abstract class Diagrams::Base' if instance_of?(Diagrams::Base)

      @version = version
      @checksum = nil # Will be calculated by subclasses via #update_checksum! after content is set
    end

    # Abstract method: Subclasses must implement this to return a hash
    # representing their specific content, suitable for serialization.
    #
    # @return [Hash]
    def to_h_content
      raise NotImplementedError, "#{self.class.name} must implement #to_h_content"
    end

    # Abstract method: Subclasses must implement this to return a hash
    # mapping element type symbols (e.g., :nodes, :edges) to arrays
    # of the corresponding element objects within the diagram.
    # Used for comparison and diffing.
    #
    # @return [Hash{Symbol => Array<Diagrams::Elements::*>}]
    def identifiable_elements
      raise NotImplementedError, "#{self.class.name} must implement #identifiable_elements"
    end

    # Performs a basic diff against another diagram object.
    # Only compares diagrams of the same type.
    # Identifies added and removed elements based on common identifiers (id/name) or object equality.
    # Does NOT currently detect modified elements.
    #
    # @param other [Diagrams::Base] The diagram to compare against.
    # @return [Hash{Symbol => Hash{Symbol => Array<Diagrams::Elements::*>}}] A hash describing differences,
    #   e.g., { nodes: { added: [...], removed: [...] }, edges: { added: [...], removed: [...] } }
    #   Returns an empty hash if diagrams are identical or of different types.
    def diff(other)
      diff_result = {}
      return diff_result unless other.is_a?(self.class) # Only compare same types
      return diff_result if self == other # Use existing equality check for quick exit

      self_elements = identifiable_elements
      other_elements = other.identifiable_elements

      # Ensure both diagrams define the same element types for comparison
      element_types = self_elements.keys & other_elements.keys

      element_types.each do |type|
        self_collection = self_elements[type] || []
        other_collection = other_elements[type] || []

        # Determine identifier method (prefer id, then name, then title, then label, fallback to object itself)
        identifier_method = if self_collection.first.respond_to?(:id)
                              :id
                            elsif self_collection.first.respond_to?(:name)
                              :name
                            elsif self_collection.first.respond_to?(:title) # For TimelineSection
                              :title
                            elsif self_collection.first.respond_to?(:label) # For Slice, TimelinePeriod
                              :label
                            else
                              :itself # Fallback to object identity/equality
                            end

        self_ids = self_collection.map(&identifier_method)
        other_ids = other_collection.map(&identifier_method)

        added_ids = other_ids - self_ids
        removed_ids = self_ids - other_ids

        added_elements = other_collection.select { |el| added_ids.include?(el.send(identifier_method)) }
        removed_elements = self_collection.select { |el| removed_ids.include?(el.send(identifier_method)) }

        # Basic check for modified elements (same ID, different content via checksum/hash if available, or simple !=)
        # This is a very basic modification check
        potential_modified_ids = self_ids & other_ids
        modified_elements = []
        potential_modified_ids.each do |id|
          self_el = self_collection.find { |el| el.send(identifier_method) == id }
          other_el = other_collection.find { |el| el.send(identifier_method) == id }
          # Use Dry::Struct equality if available, otherwise basic !=
          next unless self_el != other_el

          modified_elements << { old: self_el, new: other_el }
          # Remove from added/removed if detected as modified
          added_elements.delete(other_el)
          removed_elements.delete(self_el)
        end

        type_diff = {}
        type_diff[:added] = added_elements if added_elements.any?
        type_diff[:removed] = removed_elements if removed_elements.any?
        type_diff[:modified] = modified_elements if modified_elements.any? # Add modified info

        diff_result[type] = type_diff if type_diff.any?
      end

      diff_result
    end

    # Returns a hash representation of the diagram, suitable for serialization.
    # Includes common metadata and calls `#to_h_content` for specific data.
    #
    # @return [Hash]
    def to_h
      {
        # Extract class name without module prefix (e.g., "FlowchartDiagram")
        # Convert class name to snake_case (e.g., FlowchartDiagram -> flowchart_diagram)
        type: camel_to_snake_case(self.class.name.split('::').last),
        version: @version,
        checksum: @checksum, # Ensure checksum is up-to-date before calling
        data: to_h_content
      }
    end

    # Returns a JSON string representation of the diagram.
    # Delegates to `#to_h` and uses `JSON.generate`.
    # Accepts any arguments valid for `JSON.generate`.
    #
    # @param _args Any arguments accepted by `JSON.generate` (ignored by method signature but passed along).
    # @return [String]
    def to_json(*)
      JSON.generate(to_h, *)
    end

    # --- Class methods for Deserialization ---

    class << self
      # Deserializes a diagram from a hash representation.
      # Acts as a factory, dispatching to the appropriate subclass based on the 'type' field.
      #
      # @param hash [Hash] The hash representation (typically from parsed JSON).
      # @return [Diagrams::Base] An instance of the specific diagram subclass.
      # @raise [ArgumentError] if the hash is missing the 'type' key.
      # @raise [NameError] if the type string doesn't correspond to a known Diagram class.
      # @raise [TypeError] if the resolved class is not a subclass of Diagrams::Base.
      def from_hash(hash)
        # Ensure keys are symbols for consistent access
        symbolized_hash = hash.transform_keys(&:to_sym)

        type_string = symbolized_hash[:type]
        raise ArgumentError, "Input hash must include a 'type' key." unless type_string

        data_hash = symbolized_hash[:data] || {}
        version = symbolized_hash[:version]
        checksum = symbolized_hash[:checksum] # Pass checksum for potential verification

        begin
          # Convert snake_case type string back to CamelCase class name part
          camel_case_type = snake_to_camel_case(type_string)
          # Construct full class name (e.g., "Diagrams::FlowchartDiagram")
          klass_name = "Diagrams::#{camel_case_type}"
          klass = Object.const_get(klass_name)
        rescue NameError
          raise NameError, "Unknown diagram type '#{type_string}' corresponding to class '#{klass_name}'"
        end

        # Ensure the resolved class is actually a diagram type
        raise TypeError, "'#{klass_name}' is not a valid subclass of Diagrams::Base" unless klass < Diagrams::Base

        # Delegate to the specific subclass's from_h method
        # Each subclass must implement `from_h(data_hash, version:, checksum:)`
        klass.from_h(data_hash, version:, checksum:)
      end

      # Deserializes a diagram from a JSON string.
      # Parses the JSON and delegates to `.from_hash`.
      #
      # @param json_string [String] The JSON representation of the diagram.
      # @return [Diagrams::Base] An instance of the specific diagram subclass.
      def from_json(json_string)
        hash = JSON.parse(json_string)
        from_hash(hash)
      rescue JSON::ParserError => e
        raise JSON::ParserError, "Failed to parse JSON: #{e.message}"
      end

      private # Make helper private to the class methods

      # Simple helper to convert snake_case to CamelCase
      # (Avoids ActiveSupport dependency)
      def snake_to_camel_case(string)
        # Handle specific acronyms first
        return 'ERDiagram' if string == 'er_diagram'

        # Default conversion
        string.split('_').collect(&:capitalize).join
      end
    end

    # --- End Deserialization Methods ---

    protected

    # Recalculates the diagram's checksum based on its current content
    # and updates the @checksum instance variable.
    # Subclasses should call this after initialization and any mutation.
    def update_checksum!
      @checksum = compute_checksum
    end

    # Simple helper to convert CamelCase to snake_case
    # (Avoids ActiveSupport dependency)
    def camel_to_snake_case(string)
      string.gsub('::', '/')
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr('-', '_')
            .downcase
    end

    # Computes the SHA256 checksum of the diagram's content.
    # The content is obtained from `#to_h_content` and serialized to JSON
    # to ensure a consistent representation for hashing.
    #
    # @return [String] The hex digest of the checksum.
    def compute_checksum
      # Ensure content is available before computing checksum
      content_hash = respond_to?(:to_h_content, true) ? to_h_content : {}
      # Generate JSON. Sorting keys isn't strictly necessary for SHA256
      # but can help if comparing JSON strings directly elsewhere.
      # For checksum purposes, consistency is key, which JSON.generate provides.
      content_json = JSON.generate(content_hash || {}) # Handle potential nil from to_h_content
      Digest::SHA256.hexdigest(content_json)
    end
  end

  ## Errors (Kept from original file)
  class ValidationError < StandardError; end
  class EmptyDiagramError < ValidationError; end
  class DuplicateLabelError < ValidationError; end
end
