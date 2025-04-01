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

# 2. Define states (simple and composite)
# Use state IDs for transitions. Labels are for display.
diagram.add_state(id: 'Idle', label: 'Idle')
diagram.add_state(id: 'Loading', label: 'Loading')
# Composite state for playback
diagram.add_state(id: 'Playing', label: 'Playing', type: :composite) do |playing_state|
  # Nested states within 'Playing'
  playing_state.add_state(id: 'ShowingVideo', label: 'Showing Video')
  playing_state.add_state(id: 'ShowingControls', label: 'Showing Controls')
  # Fork/Join for concurrent nested states (conceptual representation)
  playing_state.add_state(id: 'fork_play', type: :fork)
  playing_state.add_state(id: 'join_play', type: :join)
  # Transitions within the composite state
  playing_state.add_transition(source: '[*]', target: 'fork_play') # Entry point
  playing_state.add_transition(source: 'fork_play', target: 'ShowingVideo')
  playing_state.add_transition(source: 'fork_play', target: 'ShowingControls')
  playing_state.add_transition(source: 'ShowingVideo', target: 'join_play')
  playing_state.add_transition(source: 'ShowingControls', target: 'join_play')
  playing_state.add_transition(source: 'join_play', target: '[*]') # Exit point
end
diagram.add_state(id: 'Paused', label: 'Paused')

# 3. Define top-level transitions between states
diagram.add_transition(source: '[*]', target: 'Idle') # Initial state
diagram.add_transition(source: 'Idle', target: 'Loading', label: 'Play clicked')
diagram.add_transition(source: 'Loading', target: 'Playing', label: 'Video loaded')
diagram.add_transition(source: 'Loading', target: 'Idle', label: 'Error loading')
diagram.add_transition(source: 'Playing', target: 'Paused', label: 'Pause clicked')
diagram.add_transition(source: 'Playing', target: 'Idle', label: 'Stop clicked')
diagram.add_transition(source: 'Paused', target: 'Playing', label: 'Play clicked')
diagram.add_transition(source: 'Paused', target: 'Idle', label: 'Stop clicked')

# 4. Add notes (optional)
diagram.add_note(target: 'Loading', position: :right, text: 'Buffering video data...')

# 5. Serialize to Hash
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
playing_state = reloaded_diagram.find_state('Playing')
puts "Type of 'Playing' state: #{playing_state.type}" # => :composite
puts "Number of nested states in 'Playing': #{playing_state.states.size}" # => 4 (incl. fork/join)
puts "Transition label from Idle: #{reloaded_diagram.transitions.find { |t| t.source == 'Idle'}.label}" # => Play clicked
puts "Note text: #{reloaded_diagram.notes.first.text}"

```

This example demonstrates:
- Defining simple states (`Idle`, `Loading`, `Paused`).
- Defining a composite state (`Playing`) with nested states and transitions.
- Representing fork/join pseudo-states for concurrency conceptually.
- Defining transitions between states, including initial (`[*]`) and final (`[*]`) transitions (within composite state).
- Adding labels to transitions to indicate triggering events/conditions.
- Adding notes associated with specific states.
- Standard serialization and deserialization workflow.