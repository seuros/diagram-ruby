# Entity Relationship Diagram (`Diagrams::ERDiagram`)

This diagram type models the structure of a database or domain by showing entities (like tables), their attributes (columns), and the relationships between them. It uses Crow's Foot notation for cardinality.

## Usage Example

The following example demonstrates creating an ER diagram for a simple online store, including entities with different attribute types, primary/foreign keys, identifying and non-identifying relationships, and cardinality.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new ER diagram
diagram = Diagrams::ERDiagram.new(version: '1.0')

# 2. Add entities with attributes (type, name, keys, comment)
diagram.add_entity(name: 'CUSTOMER', attributes: [
  { type: 'int', name: 'id', keys: [:PK], comment: 'Unique customer ID' },
  { type: 'varchar(100)', name: 'name' },
  { type: 'varchar(255)', name: 'email', keys: [:UK], comment: 'Unique email' },
  { type: 'timestamp', name: 'created_at' }
])

diagram.add_entity(name: 'ADDRESS', attributes: [
  { type: 'int', name: 'id', keys: [:PK] },
  { type: 'int', name: 'customer_id', keys: [:FK] },
  { type: 'varchar(50)', name: 'type', comment: 'e.g., Billing, Shipping' },
  { type: 'varchar(255)', name: 'street' },
  { type: 'varchar(100)', name: 'city' },
  { type: 'varchar(10)', name: 'zip_code' }
])

diagram.add_entity(name: 'ORDER', attributes: [
  { type: 'int', name: 'id', keys: [:PK] },
  { type: 'int', name: 'customer_id', keys: [:FK] },
  { type: 'int', name: 'shipping_address_id', keys: [:FK] },
  { type: 'timestamp', name: 'order_date' },
  { type: 'decimal(10,2)', name: 'total_amount' }
])

diagram.add_entity(name: 'ORDER_ITEM', attributes: [
  { type: 'int', name: 'order_id', keys: [:PK, :FK] }, # Composite PK
  { type: 'int', name: 'product_id', keys: [:PK, :FK] }, # Composite PK
  { type: 'int', name: 'quantity' },
  { type: 'decimal(10,2)', name: 'price_per_unit' }
])

diagram.add_entity(name: 'PRODUCT', attributes: [
  { type: 'int', name: 'id', keys: [:PK] },
  { type: 'varchar(20)', name: 'sku', keys: [:UK] },
  { type: 'varchar(255)', name: 'name' },
  { type: 'text', name: 'description' },
  { type: 'decimal(10,2)', name: 'current_price' }
])

# 3. Add relationships
# Customer ||--|{ Address : "has" (One Customer has Zero or More Addresses)
diagram.add_relationship(
  entity1: 'CUSTOMER', entity2: 'ADDRESS',
  cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE,
  label: 'has'
  # identifying: false (default)
)
# Customer ||--o{ Order : "places" (One Customer places Zero or More Orders)
diagram.add_relationship(
  entity1: 'CUSTOMER', entity2: 'ORDER',
  cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE,
  label: 'places'
)
# Order ||--|{ Order_Item : "contains" (One Order contains One or More Order Items - Identifying)
diagram.add_relationship(
  entity1: 'ORDER', entity2: 'ORDER_ITEM',
  cardinality1: :ONE_ONLY, cardinality2: :ONE_OR_MORE,
  identifying: true, label: 'contains'
)
# Product ||--o{ Order_Item : "appears in" (One Product appears in Zero or More Order Items - Identifying)
diagram.add_relationship(
  entity1: 'PRODUCT', entity2: 'ORDER_ITEM',
  cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE,
  identifying: true, label: 'appears in'
)
# Order }o..o| Address : "ships to" (One Order ships to Zero or One Addresses - Non-identifying, Optional)
diagram.add_relationship(
  entity1: 'ORDER', entity2: 'ADDRESS',
  cardinality1: :ZERO_OR_MORE, cardinality2: :ZERO_OR_ONE,
  identifying: false, label: 'ships to'
)


# 4. Serialize to Hash
diagram_hash = diagram.to_h
puts "Serialized Hash:"
pp diagram_hash
# Output will be a hash representing the ERD structure.

# 5. Deserialize from Hash
reloaded_diagram = Diagrams::Base.from_hash(diagram_hash)

# 6. Verify
puts "\nVerification:"
puts "Reloaded diagram class: #{reloaded_diagram.class}"
puts "Original checksum:   #{diagram.checksum}"
puts "Reloaded checksum:   #{reloaded_diagram.checksum}"
puts "Checksums match?     #{diagram.checksum == reloaded_diagram.checksum}"
puts "Diagrams equal?      #{diagram == reloaded_diagram}"

# Access data from reloaded diagram
puts "Number of entities: #{reloaded_diagram.entities.size}" # => 5
order_item = reloaded_diagram.find_entity('ORDER_ITEM')
puts "ORDER_ITEM attributes: #{order_item.entity_attributes.map(&:name)}"
contains_rel = reloaded_diagram.relationships.find { |r| r.label == 'contains' }
puts "Relationship 'contains' is identifying: #{contains_rel.identifying}" # => true
puts "Cardinality ORDER -> ORDER_ITEM: #{contains_rel.cardinality2}" # => :ONE_OR_MORE

```

This example demonstrates:
- Defining multiple entities with various attribute types.
- Specifying primary (`:PK`), foreign (`:FK`), and unique (`:UK`) keys. Keys can be composite.
- Adding comments to attributes.
- Creating different relationship types with varying cardinalities using Crow's Foot notation symbols (`:ZERO_OR_ONE`, `:ONE_ONLY`, `:ZERO_OR_MORE`, `:ONE_OR_MORE`).
- Distinguishing between identifying (`identifying: true`) and non-identifying relationships.
- Adding descriptive labels to relationships.
- Standard serialization and deserialization workflow.