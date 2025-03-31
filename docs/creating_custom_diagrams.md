# Creating Custom Diagram Types

The `diagram` gem is designed to be extensible, allowing you to define your own custom diagram types alongside the built-in ones (Flowchart, ClassDiagram, etc.). Here's how you can create and integrate your own diagram type:

## 1. Define Your Diagram Class

Create a new Ruby class that inherits from `Diagrams::Base`. Place this file within your project where Zeitwerk (or your application's loader) can find it, typically following the convention `lib/diagrams/my_custom_diagram.rb` if you want it autoloaded within the `Diagrams` namespace.

```ruby
# lib/diagrams/my_custom_diagram.rb
require_relative 'base'
# Require any custom element structs you might define
# require_relative 'elements/my_custom_element'

module Diagrams
  class MyCustomDiagram < Base
    # Use attr_reader for the specific data your diagram holds
    attr_reader :custom_data_points, :title

    # Define an initializer
    # - Accept specific data (e.g., `custom_data_points`) and optional `version`.
    # - Call `super(version: version)`.
    # - Store the data in instance variables.
    # - Perform any necessary validation (`validate_elements!`).
    # - Call `update_checksum!` at the end.
    def initialize(title: '', custom_data_points: [], version: 1)
      super(version: version)
      @title = title
      @custom_data_points = custom_data_points
      validate_elements!
      update_checksum!
    end

    # Implement the required #to_h_content method
    # This should return a hash containing only the specific data for your diagram type.
    # Ensure any custom element objects are also converted to hashes via their own `to_h`.
    # @return [Hash]
    def to_h_content
      {
        title: @title,
        # Example: assuming MyCustomElement has a #to_h method
        custom_data_points: @custom_data_points.map(&:to_h)
      }
    end

    # Implement the required .from_h class method
    # This is used by the `Diagrams::Base.from_h` factory for deserialization.
    # - It receives the `data_hash` (content from `to_h_content`), `version`, and `checksum`.
    # - Instantiate your custom element objects from the `data_hash`.
    # - Create a new instance of your diagram class using `new(...)`.
    # - Optionally, verify the passed `checksum` against the new instance's checksum.
    # @param data_hash [Hash]
    # @param version [String, Integer, nil]
    # @param checksum [String, nil]
    # @return [MyCustomDiagram]
    def self.from_h(data_hash, version:, checksum:)
      title = data_hash[:title] || ''
      points_data = data_hash[:custom_data_points] || []

      # Example: assuming MyCustomElement can be created from a hash
      custom_points = points_data.map { |point_h| Elements::MyCustomElement.new(point_h.transform_keys(&:to_sym)) }

      diagram = new(title: title, custom_data_points: custom_points, version: version)

      # Optional checksum verification
      if checksum && diagram.checksum != checksum
        warn "Checksum mismatch for loaded MyCustomDiagram (version: #{version})."
      end

      diagram
    end

    # Add any methods specific to your diagram type
    def add_data_point(point)
      # Add validation if needed
      @custom_data_points << point
      update_checksum!
      point
    end

    private

    # Implement custom validation logic if needed
    def validate_elements!
      # Example: Ensure no duplicate points, etc.
      # raise ArgumentError, "Invalid data points" unless ...
    end
  end
end
```

## 2. Define Custom Element Structs (If Needed)

If your diagram uses specific types of elements, define them as `Dry::Struct` classes, typically within the `Diagrams::Elements` namespace.

```ruby
# lib/diagrams/elements/my_custom_element.rb
require 'dry-struct'
require_relative 'node' # Or a dedicated types file to get Diagrams::Elements::Types

module Diagrams
  module Elements
    class MyCustomElement < Dry::Struct
      include Diagrams::Elements::Types # Use shared types

      attribute :name, Types::Strict::String.constrained(min_size: 1)
      attribute :value, Types::Strict::Integer

      def to_h
        super # Dry::Struct provides a default
      end
    end
  end
end
```

## 3. Usage

Once defined, your custom diagram class works just like the built-in ones:

```ruby
require 'diagrams'
# Ensure your custom files are loaded if not using Zeitwerk correctly
# require_relative 'path/to/diagrams/my_custom_diagram'
# require_relative 'path/to/diagrams/elements/my_custom_element'

# Create instance
my_diagram = Diagrams::MyCustomDiagram.new(title: 'My Data')
point1 = Diagrams::Elements::MyCustomElement.new(name: 'Point A', value: 100)
my_diagram.add_data_point(point1)

# Serialize
json_data = my_diagram.to_json
puts json_data
# => {"type":"MyCustomDiagram","version":1,"checksum":"...","data":{"title":"My Data","custom_data_points":[{"name":"Point A","value":100}]}}

# Deserialize
loaded_diagram = Diagrams::Base.from_json(json_data)

puts loaded_diagram.class # => Diagrams::MyCustomDiagram
puts loaded_diagram.title # => My Data
```

By following these steps and adhering to the interface expected by `Diagrams::Base` (`initialize`, `#to_h_content`, `.from_h`), your custom diagram type will seamlessly integrate with the gem's core features like serialization, deserialization, versioning, and checksumming.