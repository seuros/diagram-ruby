# Pie Diagram (`Diagrams::PieDiagram`)

This diagram type represents data as slices of a circle, where each slice's size is proportional to the value it represents. It's useful for showing the composition of a whole.

## Usage Example

The following example demonstrates creating a pie chart showing browser market share, including a title and data slices, then serializing and deserializing it.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new Pie diagram
diagram = Diagrams::PieDiagram.new(title: 'Browser Market Share - Q1 2025', version: '3.0')

# 2. Add data slices
# Each slice needs a label (String) and a value (Numeric).
diagram.add_slice(label: 'Chrome', value: 65.8)
diagram.add_slice(label: 'Safari', value: 18.5)
diagram.add_slice(label: 'Edge', value: 5.2)
diagram.add_slice(label: 'Firefox', value: 3.1)
# Add a slice representing multiple smaller browsers
diagram.add_slice(label: 'Others', value: 100 - (65.8 + 18.5 + 5.2 + 3.1)) # Calculate remaining percentage

# 3. Serialize to Hash
diagram_hash = diagram.to_h
puts "Serialized Hash:"
pp diagram_hash
# Output will be a hash like:
# {:type=>"pie_diagram",
#  :version=>"3.0",
#  :checksum=>"...",
#  :data=>
#   {:title=>"Browser Market Share - Q1 2025",
#    :slices=>
#     [{:label=>"Chrome", :value=>65.8},
#      {:label=>"Safari", :value=>18.5},
#      {:label=>"Edge", :value=>5.2},
#      {:label=>"Firefox", :value=>3.1},
#      {:label=>"Others", :value=>7.399999999999991}]}} # Note potential floating point inaccuracies


# 4. Deserialize from Hash
reloaded_diagram = Diagrams::Base.from_hash(diagram_hash)

# 5. Verify
puts "\nVerification:"
puts "Reloaded diagram class: #{reloaded_diagram.class}"
puts "Original checksum:   #{diagram.checksum}"
puts "Reloaded checksum:   #{reloaded_diagram.checksum}"
puts "Checksums match?     #{diagram.checksum == reloaded_diagram.checksum}"
puts "Diagrams equal?      #{diagram == reloaded_diagram}"

# Access data from reloaded diagram
puts "Reloaded title: #{reloaded_diagram.title}" # => Browser Market Share - Q1 2025
puts "Number of slices: #{reloaded_diagram.slices.size}" # => 5
# Find a specific slice
edge_slice = reloaded_diagram.slices.find { |s| s.label == 'Edge' }
puts "Value for Edge: #{edge_slice.value if edge_slice}" # => 5.2

```

This example demonstrates:
- Setting a title for the pie chart.
- Adding data slices with labels and numeric values.
- Calculating a value for an "Others" category.
- Standard serialization and deserialization workflow.