# Class Diagram (`Diagrams::ClassDiagram`)

This diagram type represents the structure of an object-oriented system, showing classes, their attributes, methods, and the relationships between them (like inheritance, composition, association).

## Usage Example

The following example demonstrates creating a class diagram with multiple classes, attributes, methods, inheritance, and association, then serializing and deserializing it.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new Class diagram
diagram = Diagrams::ClassDiagram.new(version: '1.0')

# 2. Add classes with attributes and methods
vehicle = diagram.add_class(
  name: 'Vehicle',
  attributes: ['+max_speed: int', '-current_speed: int'],
  methods: ['+start()', '+stop()', '#accelerate(amount: int)']
)

car = diagram.add_class(
  name: 'Car',
  attributes: ['-num_doors: int'],
  methods: ['+open_trunk()']
)

engine = diagram.add_class(
  name: 'Engine',
  attributes: ['~horsepower: int'],
  methods: ['+ignite()']
)

driver = diagram.add_class(
  name: 'Driver',
  attributes: ['+name: string'],
  methods: ['+drive(vehicle: Vehicle)']
)

# 3. Add relationships
# Inheritance (Car -> Vehicle)
diagram.add_relationship(
  type: :inheritance,
  source: car.name, # Use class name as ID
  target: vehicle.name
)

# Composition (Car has an Engine)
diagram.add_relationship(
  type: :composition,
  source: car.name,
  target: engine.name,
  label: '1' # Cardinality (Car has 1 Engine)
)

# Association (Driver drives a Vehicle)
diagram.add_relationship(
  type: :association,
  source: driver.name,
  target: vehicle.name,
  label: 'drives >' # Label and direction
)


# 4. Serialize to JSON
json_string = diagram.to_json
puts "Serialized JSON:"
puts JSON.pretty_generate(JSON.parse(json_string))
# Output will be a JSON string representing the class diagram structure.
# {
#   "type": "class_diagram",
#   "version": "1.0",
#   "checksum": "...",
#   "data": {
#     "classes": [
#       { "name": "Vehicle", "attributes": ["+max_speed: int", "-current_speed: int"], "methods": ["+start()", "+stop()", "#accelerate(amount: int)"] },
#       { "name": "Car", "attributes": ["-num_doors: int"], "methods": ["+open_trunk()"] },
#       { "name": "Engine", "attributes": ["~horsepower: int"], "methods": ["+ignite()"] },
#       { "name": "Driver", "attributes": ["+name: string"], "methods": ["+drive(vehicle: Vehicle)"] }
#     ],
#     "relationships": [
#       { "type": "inheritance", "source": "Car", "target": "Vehicle" },
#       { "type": "composition", "source": "Car", "target": "Engine", "label": "1" },
#       { "type": "association", "source": "Driver", "target": "Vehicle", "label": "drives >" }
#     ]
#   }
# }


# 5. Deserialize from JSON
reloaded_diagram = Diagrams::Base.from_json(json_string)

# 6. Verify
puts "\nVerification:"
puts "Reloaded diagram class: #{reloaded_diagram.class}"
puts "Original checksum:   #{diagram.checksum}"
puts "Reloaded checksum:   #{reloaded_diagram.checksum}"
puts "Checksums match?     #{diagram.checksum == reloaded_diagram.checksum}"
puts "Diagrams equal?      #{diagram == reloaded_diagram}"

# Access data from reloaded diagram
puts "Number of classes: #{reloaded_diagram.classes.size}" # => 4
puts "Car attributes: #{reloaded_diagram.find_class('Car').attributes}" # => ["-num_doors: int"]
puts "Number of relationships: #{reloaded_diagram.relationships.size}" # => 3
puts "Driver relationship type: #{reloaded_diagram.relationships.last.type}" # => :association

```

This example demonstrates:
- Defining classes with attributes and methods using visibility markers (`+`, `-`, `#`, `~`).
- Adding different types of relationships: inheritance, composition, association.
- Adding labels (like cardinality or descriptions) to relationships.
- Standard serialization and deserialization workflow.