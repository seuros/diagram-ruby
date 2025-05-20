# State Diagram (`Diagrams::StateDiagram`)

This diagram type models the behavior of systems by showing states and the transitions between them based on events or conditions. It can represent simple state machines or complex nested/concurrent states.

## Usage Example

The following example demonstrates creating a state diagram for a simple video player, including composite states, forks/joins (for concurrency), notes, and transitions, then serializing and deserializing it.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new State diagram
diagram = Diagrams::StateDiagram.new(version: '1.2')

# 2. Define states
# Use state IDs for transitions. Labels are for display.
idle    = Diagrams::Elements::State.new(id: 'Idle',    label: 'Idle')
loading = Diagrams::Elements::State.new(id: 'Loading', label: 'Loading')
playing = Diagrams::Elements::State.new(id: 'Playing', label: 'Playing')
paused  = Diagrams::Elements::State.new(id: 'Paused',  label: 'Paused')
start   = Diagrams::Elements::State.new(id: '[*]', label: '[*]')

diagram.add_state(idle)
diagram.add_state(loading)
diagram.add_state(playing)
diagram.add_state(paused)
diagram.add_state(start)

# 3. Define top-level transitions between states
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: '[*]', target_state_id: 'Idle')) # Initial state
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Idle', target_state_id: 'Loading', label: 'Play clicked'))
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Loading', target_state_id: 'Playing', label: 'Video loaded'))
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Loading', target_state_id: 'Idle', label: 'Error loading'))
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Playing', target_state_id: 'Paused', label: 'Pause clicked'))
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Playing', target_state_id: 'Idle', label: 'Stop clicked'))
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Paused', target_state_id: 'Playing', label: 'Play clicked'))
diagram.add_transition(Diagrams::Elements::Transition.new(source_state_id: 'Paused', target_state_id: 'Idle', label: 'Stop clicked'))

# 4. Serialize to Hash
diagram_hash = diagram.to_h
puts "Serialized Hash:"
pp diagram_hash
# Output will be a hash representing the state diagram structure, including nested states.
# (Structure is complex due to nesting, showing only top-level here)
# {:type=>"state_diagram",
#  :version=>"1.2",
#  :checksum=>"...",
#  :data=>
#   {:states=>
#     [{:id=>"Idle", :label=>"Idle", :type=>:simple},
#      {:id=>"Loading", :label=>"Loading", :type=>:simple},
#      {:id=>"Playing", :label=>"Playing", :type=>:composite, :states=>[...], :transitions=>[...]}, # Nested data omitted
#      {:id=>"Paused", :label=>"Paused", :type=>:simple}],
#    :transitions=>
#     [{:source=>"[*]", :target=>"Idle"},
#      {:source=>"Idle", :target=>"Loading", :label=>"Play clicked"},
#      {:source=>"Loading", :target=>"Playing", :label=>"Video loaded"},
#      {:source=>"Loading", :target=>"Idle", :label=>"Error loading"},
#      {:source=>"Playing", :target=>"Paused", :label=>"Pause clicked"},
#      {:source=>"Playing", :target=>"Idle", :label=>"Stop clicked"},
#      {:source=>"Paused", :target=>"Playing", :label=>"Play clicked"},
#      {:source=>"Paused", :target=>"Idle", :label=>"Stop clicked"}],
#    :notes=>
#     [{:target=>"Loading", :position=>:right, :text=>"Buffering video data..."}]}}


# 6. Deserialize from Hash
reloaded_diagram = Diagrams::Base.from_hash(diagram_hash)

# 7. Verify
puts "\nVerification:"
puts "Reloaded diagram class: #{reloaded_diagram.class}"
puts "Original checksum:   #{diagram.checksum}"
puts "Reloaded checksum:   #{reloaded_diagram.checksum}"
puts "Checksums match?     #{diagram.checksum == reloaded_diagram.checksum}"
puts "Diagrams equal?      #{diagram == reloaded_diagram}"

# Access data from reloaded diagram
puts "Number of top-level states: #{reloaded_diagram.states.size}" # => 4
puts "First transition label: #{reloaded_diagram.transitions[1].label}" # => Play clicked

```

This example demonstrates:
- Defining states (`Idle`, `Loading`, `Playing`, `Paused`).
- Defining transitions between states with optional labels.
- Standard serialization and deserialization workflow.
