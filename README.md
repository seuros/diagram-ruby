# Diagrams Gem

[![Gem Version](https://badge.fury.io/rb/diagram.svg)](https://badge.fury.io/rb/diagram)
<!-- Add badges for Build Status, Code Climate, etc. once CI/analysis is set up -->

**Diagrams** provides Ruby objects for defining and manipulating various diagram types (Flowcharts, Class Diagrams, Gantt Charts, Pie Charts, State Diagrams). It focuses on the *data structure and logic*, allowing other tools or gems to handle rendering (e.g., to Mermaid, Graphviz, etc.).

**Key Goals:**

*   **Developer Experience & Extensibility:** Clean API, easy to extend.
*   **Modern Ruby (3.3+):** Uses modern practices like RBS type signatures and `dry-rb` gems.
*   **Uniform Capabilities:** Consistent serialization (Hash/JSON), comparison, versioning, and checksums across all diagram types.
*   **Separation of Concerns:** Core gem handles data only, not rendering or persistence.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'diagram', '~> 0.3.0' # Or appropriate version constraint
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install diagram
```

## Usage

### Creating Diagrams

Require the gem and instantiate specific diagram classes.

```ruby
require 'diagram'

# --- Flowchart Example ---
flowchart = Diagrams::FlowchartDiagram.new(version: '1.0')

# Create nodes (using Diagrams::Elements::Node)
node1 = Diagrams::Elements::Node.new(id: 'start', label: 'Start Process')
node2 = Diagrams::Elements::Node.new(id: 'step1', label: 'Do Something')
node3 = Diagrams::Elements::Node.new(id: 'end', label: 'End Process')

# Add nodes to the diagram
flowchart.add_node(node1)
flowchart.add_node(node2)
flowchart.add_node(node3)

# Create and add edges (using Diagrams::Elements::Edge)
edge1 = Diagrams::Elements::Edge.new(source_id: 'start', target_id: 'step1')
edge2 = Diagrams::Elements::Edge.new(source_id: 'step1', target_id: 'end', label: 'Finished')
flowchart.add_edge(edge1)
flowchart.add_edge(edge2)

puts "Flowchart Nodes: #{flowchart.nodes.map(&:id)}"
# => Flowchart Nodes: ["start", "step1", "end"]

# --- Class Diagram Example ---
class_diagram = Diagrams::ClassDiagram.new(version: 2)

# Create class entities (using Diagrams::Elements::ClassEntity)
user_class = Diagrams::Elements::ClassEntity.new(
  name: 'User',
  attributes: ['id: Integer', 'email: String'],
  methods: ['authenticate(password: String): Boolean']
)
order_class = Diagrams::Elements::ClassEntity.new(
  name: 'Order',
  attributes: ['order_id: Integer', 'amount: Float']
)

# Add classes
class_diagram.add_class(user_class)
class_diagram.add_class(order_class)

# Create and add relationships (using Diagrams::Elements::Relationship)
rel = Diagrams::Elements::Relationship.new(
  source_class_name: 'User',
  target_class_name: 'Order',
  type: 'has_many',
  label: 'places'
)
class_diagram.add_relationship(rel)

puts "Class Diagram Classes: #{class_diagram.classes.map(&:name)}"
# => Class Diagram Classes: ["User", "Order"]

# --- Pie Chart Example ---
pie_chart = Diagrams::PieDiagram.new(title: 'Browser Share', version: '2024-Q1')

# Create and add slices (using Diagrams::Elements::Slice)
slice1 = Diagrams::Elements::Slice.new(label: 'Chrome', value: 65.5)
slice2 = Diagrams::Elements::Slice.new(label: 'Firefox', value: 15.0)
slice3 = Diagrams::Elements::Slice.new(label: 'Safari', value: 10.5)
slice4 = Diagrams::Elements::Slice.new(label: 'Edge', value: 5.0)
# slice5 = Diagrams::Elements::Slice.new(label: 'Other', value: 4.0) # Total must be <= 100

pie_chart.add_slice(slice1)
pie_chart.add_slice(slice2)
pie_chart.add_slice(slice3)
pie_chart.add_slice(slice4)
# pie_chart.add_slice(slice5)

puts "Pie Chart Total: #{pie_chart.total_value}%"
# => Pie Chart Total: 96.0%

# (Examples for Gantt and State diagrams can be added similarly)
```

### Serialization & Deserialization

All diagrams can be serialized to a Hash or JSON string, and deserialized back into objects.

```ruby
# Serialization
flowchart_hash = flowchart.to_h
flowchart_json = flowchart.to_json

puts flowchart_json
# => {"type":"FlowchartDiagram","version":"1.0","checksum":"...","data":{"nodes":[...],"edges":[...]}}

# Deserialization (using the Base class factory)
loaded_flowchart = Diagrams::Base.from_json(flowchart_json)
# or
# loaded_flowchart = Diagrams::Base.from_hash(flowchart_hash)

puts "Loaded diagram type: #{loaded_flowchart.class}"
# => Loaded diagram type: Diagrams::FlowchartDiagram
puts "Loaded diagram version: #{loaded_flowchart.version}"
# => Loaded diagram version: 1.0

# Verify content equality (ignores version)
original_flowchart = Diagrams::FlowchartDiagram.new(
  nodes: [node1, node2, node3],
  edges: [edge1, edge2],
  version: 'Different Version' # Version doesn't affect equality check
)
puts "Diagrams have same content? #{loaded_flowchart == original_flowchart}"
# => Diagrams have same content? true
```

### Versioning and Checksums

Each diagram has:

*   `#version`: A user-managed field (passed during initialization) for tracking revisions.
*   `#checksum`: An automatically calculated SHA256 hash of the diagram's content (nodes, edges, etc.). This changes whenever the content is modified via methods like `add_node`, `add_slice`, etc.

You can use the checksum to quickly detect if a diagram's content has changed. The `==` operator compares diagrams based on their type and checksum (content), ignoring the `version` field.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/diagrams/version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/seuros/diagram-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
