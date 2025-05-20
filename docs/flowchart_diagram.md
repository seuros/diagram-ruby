# Flowchart Diagram (`Diagrams::FlowchartDiagram`)

This diagram type represents processes or workflows using nodes (for steps, decisions, start/end points) and edges (for flow direction and connections).

## Usage Example

The following example demonstrates creating a flowchart for a simple login process, including different node shapes and edge labels, then serializing and deserializing it.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new Flowchart diagram
diagram = Diagrams::FlowchartDiagram.new(version: '2.1')

# 2. Add nodes with different labels
# Node shapes are typically handled by the rendering tool (like Mermaid),
# but we can represent the *intent* in the label or use specific node types if defined.
# Here, we create `Node` objects first and then add them to the diagram.
start_node = Diagrams::Elements::Node.new(id: 'start', label: 'Start')
input_node = Diagrams::Elements::Node.new(id: 'input', label: 'Enter Credentials')
decision_node = Diagrams::Elements::Node.new(id: 'check', label: 'Credentials Valid?')
success_node = Diagrams::Elements::Node.new(id: 'success', label: 'Login Successful')
fail_node = Diagrams::Elements::Node.new(id: 'fail', label: 'Login Failed')
end_node = Diagrams::Elements::Node.new(id: 'end', label: 'End')

diagram.add_node(start_node)
diagram.add_node(input_node)
diagram.add_node(decision_node)
diagram.add_node(success_node)
diagram.add_node(fail_node)
diagram.add_node(end_node)

# 3. Add edges connecting the nodes, with labels for decisions
diagram.add_edge(Diagrams::Elements::Edge.new(source_id: start_node.id, target_id: input_node.id))
diagram.add_edge(Diagrams::Elements::Edge.new(source_id: input_node.id, target_id: decision_node.id))
diagram.add_edge(Diagrams::Elements::Edge.new(source_id: decision_node.id, target_id: success_node.id, label: 'Yes'))
diagram.add_edge(Diagrams::Elements::Edge.new(source_id: decision_node.id, target_id: fail_node.id, label: 'No'))
diagram.add_edge(Diagrams::Elements::Edge.new(source_id: success_node.id, target_id: end_node.id))
diagram.add_edge(Diagrams::Elements::Edge.new(source_id: fail_node.id, target_id: end_node.id))

# 4. Serialize to Hash
diagram_hash = diagram.to_h
puts "Serialized Hash:"
pp diagram_hash
# Output will be a hash like:
# {:type=>"flowchart_diagram",
#  :version=>"2.1",
#  :checksum=>"...",
#  :data=>
#   {:nodes=>
#     [{:id=>"start", :label=>"Start"},
#      {:id=>"input", :label=>"Enter Credentials"},
#      {:id=>"check", :label=>"Credentials Valid?"},
#      {:id=>"success", :label=>"Login Successful"},
#      {:id=>"fail", :label=>"Login Failed"},
#      {:id=>"end", :label=>"End"}],
#    :edges=>
#     [{:source_id=>"start", :target_id=>"input"},
#      {:source_id=>"input", :target_id=>"check"},
#      {:source_id=>"check", :target_id=>"success", :label=>"Yes"},
#      {:source_id=>"check", :target_id=>"fail", :label=>"No"},
#      {:source_id=>"success", :target_id=>"end"},
#      {:source_id=>"fail", :target_id=>"end"}]}}


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
puts "Number of nodes: #{reloaded_diagram.nodes.size}" # => 6
puts "Decision node label: #{reloaded_diagram.find_node('check').label}" # => Credentials Valid?
puts "Edge from decision to success label: #{reloaded_diagram.edges.find { |e| e.source_id == 'check' && e.target_id == 'success'}.label}" # => Yes

```

This example demonstrates:
- Defining nodes representing different steps in a process.
- Connecting nodes with edges to show the flow.
- Adding labels to edges, often used for decision branches (`Yes`/`No`).
- Standard serialization and deserialization workflow using hashes.