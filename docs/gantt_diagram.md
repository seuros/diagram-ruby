# Gantt Diagram (`Diagrams::GanttDiagram`)

This diagram type is used for project scheduling, illustrating tasks, their durations, start/end dates, and dependencies over a timeline.

## Usage Example

The following example demonstrates creating a Gantt chart for a small project, including sections, tasks with different statuses (done, active, future), and dependencies, then serializing and deserializing it.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new Gantt diagram
# Note: Date formats and axis formatting are typically handled by rendering tools.
# This structure focuses on the task data.
diagram = Diagrams::GanttDiagram.new(version: '0.5')

# 2. Add sections and tasks
# Sections group related tasks.
diagram.add_section('Planning Phase')
# Tasks require a label, status, and start/duration information.
# Status can be :done, :active, or inferred as future if start is later.
# Start/duration can be dates, IDs (for dependencies), or relative terms.
task1 = diagram.add_task(label: 'Market Research', status: :done, start: '2024-01-01', duration: '7d')
task2 = diagram.add_task(label: 'Define Requirements', status: :done, start: 'after task1', duration: '5d') # Dependency
task3 = diagram.add_task(label: 'Create Mockups', status: :active, start: 'after task2', duration: '10d')

diagram.add_section('Development Phase')
task4 = diagram.add_task(label: 'Setup Environment', status: :active, start: 'after task2', duration: '3d') # Parallel to task3
task5 = diagram.add_task(label: 'Implement Core Features', start: 'after task3, task4', duration: '20d') # Depends on two tasks
task6 = diagram.add_task(label: 'Testing', start: 'after task5', duration: '10d')

# 3. Serialize to Hash
diagram_hash = diagram.to_h
puts "Serialized Hash:"
pp diagram_hash
# Output will be a hash like:
# {:type=>"gantt_diagram",
#  :version=>"0.5",
#  :checksum=>"...",
#  :data=>
#   {:sections=>
#     [{:title=>"Planning Phase",
#       :tasks=>
#        [{:label=>"Market Research", :status=>:done, :start=>"2024-01-01", :duration=>"7d"},
#         {:label=>"Define Requirements", :status=>:done, :start=>"after task1", :duration=>"5d"},
#         {:label=>"Create Mockups", :status=>:active, :start=>"after task2", :duration=>"10d"}]},
#      {:title=>"Development Phase",
#       :tasks=>
#        [{:label=>"Setup Environment", :status=>:active, :start=>"after task2", :duration=>"3d"},
#         {:label=>"Implement Core Features", :start=>"after task3, task4", :duration=>"20d"},
#         {:label=>"Testing", :start=>"after task5", :duration=>"10d"}]}]}}


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
puts "Number of sections: #{reloaded_diagram.sections.size}" # => 2
puts "First task label: #{reloaded_diagram.sections[0].tasks[0].label}" # => Market Research
puts "Status of Create Mockups: #{reloaded_diagram.sections[0].tasks[2].status}" # => :active
puts "Start dependency of Testing task: #{reloaded_diagram.sections[1].tasks[2].start}" # => after task5

```

This example demonstrates:
- Grouping tasks into sections.
- Defining tasks with labels, statuses (`:done`, `:active`, or future implied).
- Specifying start times using absolute dates (`2024-01-01`) or relative dependencies (`after task_id`, `after task_id1, task_id2`).
- Specifying durations (e.g., `7d`, `10d`).
- Standard serialization and deserialization workflow.