# Timeline Diagram (`Diagrams::TimelineDiagram`)

This diagram type represents a chronology of events, potentially grouped into sections or ages. It's useful for visualizing historical events, project milestones, or any sequence of occurrences over time.

## Usage Example

The following example demonstrates creating a timeline related to Donald Trump's political career and the MAGA movement, including a hypothetical future event, serializing it, and deserializing it.

```ruby
require 'diagrams' # Assuming the gem is loaded
require 'json'     # For JSON serialization/deserialization
require 'pp'       # For pretty printing hashes

# 1. Create a new Timeline diagram
diagram = Diagrams::TimelineDiagram.new(title: 'Timeline Example: Trump Political Career & MAGA Movement', version: '1.1')

# 2. Add sections and periods/events chronologically
diagram.add_section('Campaign & Election')
diagram.add_period(period_label: '2015', events: 'Announces presidential campaign')
diagram.add_period(period_label: '2016', events: 'Wins presidential election')

diagram.add_section('Presidency')
diagram.add_period(period_label: '2017', events: [
  'Inaugurated as 45th President',
  'Signs EO 13769 (Travel Ban)',
  'Tax Cuts and Jobs Act signed'
])
diagram.add_period(period_label: '2019', events: 'House initiates impeachment inquiry')
diagram.add_period(period_label: '2020', events: ['Addresses COVID-19 pandemic response', 'Presidential election held'])
diagram.add_period(period_label: 'Jan 2021', events: ['January 6th events at US Capitol', 'Presidency concludes'])

diagram.add_section('Post-Presidency & Future')
diagram.add_period(period_label: '2021-2024', events: ['Continued political activity', 'MAGA movement remains influential'])
# Hypothetical future event for example purposes
diagram.add_period(period_label: 'Jan 2025', events: 'Inaugurated as 47th President (Hypothetical)')

# 3. Serialize to JSON
json_string = diagram.to_json
puts "Serialized JSON:"
puts JSON.pretty_generate(JSON.parse(json_string))
# Output will be a JSON string representing the timeline structure.
# (Output structure similar to previous example, but with different data)

# 4. Deserialize from JSON
reloaded_diagram = Diagrams::Base.from_json(json_string)

# 5. Verify
puts "\nVerification:"
puts "Reloaded diagram class: #{reloaded_diagram.class}"
puts "Original checksum:   #{diagram.checksum}"
puts "Reloaded checksum:   #{reloaded_diagram.checksum}"
puts "Checksums match?     #{diagram.checksum == reloaded_diagram.checksum}"
puts "Diagrams equal?      #{diagram == reloaded_diagram}"

# Access data from reloaded diagram
puts "Reloaded title: #{reloaded_diagram.title}"
puts "Number of sections: #{reloaded_diagram.sections.size}"
puts "Events in Jan 2025: #{reloaded_diagram.sections.last.periods.last.events.map(&:description)}"

```

This example demonstrates:
- Grouping events into logical sections.
- Adding multiple distinct events within a single time period.
- Representing a span of time.
- Including a hypothetical future event for illustrative purposes.
- Standard serialization and deserialization workflow.