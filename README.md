# diagram

[![Gem Version](https://badge.fury.io/rb/diagram.svg)](https://badge.fury.io/rb/diagram)

Diagrams as plain Ruby data: flowcharts, state, class, ER, Gantt, pie,
timeline and git graphs. Build them, compare them, diff them, serialize them.
Rendering is someone else's job: the [mermaid](https://github.com/seuros/mermaid-ruby)
gem turns these into Mermaid text.

- One way to build each diagram: `new(title:)`, then its `add_*` methods.
- Elements are immutable `Data` values, compared by value.
- Wrong types raise `TypeError` (`false` is not "absent"); bad values raise
  `ArgumentError` (`RangeError` for numbers). Numbers are Integers or finite
  Floats. Loading from a hash or with Marshal runs the same checks.
- Ruby 4.0+, no dependencies beyond `zeitwerk` and `json`.

## Installation

```ruby
gem 'diagram'
```

## Usage

```ruby
require 'diagram'

flow = Diagrams::FlowchartDiagram.new(title: 'Deploy')
flow.add_node(id: 'build', label: 'Build')
flow.add_node(id: 'ship', label: 'Ship')
flow.add_edge(source_id: 'build', target_id: 'ship', label: 'green')

flow.nodes.map(&:id)    # => ["build", "ship"]
flow.add_edge(source_id: 'ship', target_id: 'pray') # => ArgumentError: no node "pray"
```

Every `add_*` returns the element it added. Collections are frozen arrays.

### The other diagram types

```ruby
door = Diagrams::StateDiagram.new(title: 'Door')
door.add_state(id: 'closed')
door.add_state(id: 'open', label: 'Open')
door.add_transition(source_state_id: '*', target_state_id: 'closed') # '*' is the initial/final pseudo-state
door.add_transition(source_state_id: 'closed', target_state_id: 'open', label: 'push', guard: 'unlocked')

classes = Diagrams::ClassDiagram.new
classes.add_class(name: 'Animal', attributes: ['+String name'], operations: ['+speak() String'])
classes.add_class(name: 'Duck')
classes.add_relationship(source_class_name: 'Animal', target_class_name: 'Duck', type: :inheritance)

shop = Diagrams::ERDiagram.new
shop.add_entity(name: 'CUSTOMER', attributes: [{ type: 'int', name: 'id', keys: [:PK] },
                                               { type: 'string', name: 'email', keys: [:UK] }])
shop.add_entity(name: 'ORDER')
shop.add_relationship(entity1: 'CUSTOMER', entity2: 'ORDER',
                      cardinality1: :ONE_ONLY, cardinality2: :ZERO_OR_MORE, label: 'places')

pets = Diagrams::PieDiagram.new(title: 'Pets')
pets.add_slice(label: 'Dogs', value: 3)
pets.add_slice(label: 'Cats', value: 1)
pets.percentages # => {"Dogs" => 75.0, "Cats" => 25.0}

plan = Diagrams::GanttDiagram.new(title: 'Launch')
plan.add_section(title: 'Design')
plan.add_task(id: 'spec', label: 'Spec', start: '2026-01-05', duration: '3d', status: :done)
plan.add_section(title: 'Build', tasks: [{ id: 'code', label: 'Code', start: 'after spec', duration: '2w' }])

history = Diagrams::TimelineDiagram.new(title: 'Social media')
history.add_period(label: '2004', events: %w[Facebook Gmail])
history.add_section(title: 'Video')
history.add_period(label: '2005', events: ['YouTube'])

git = Diagrams::GitgraphDiagram.new # main branch "main"
git.commit(id: 'init')
git.branch(name: 'feature')
git.commit(message: 'work')
git.checkout(name: 'main')
git.merge(from_branch_name: 'feature', tag: 'v1')
```

Gantt tasks and timeline periods go to the last section; one added before any
section opens an untitled section.

### Serialize, compare, diff

```ruby
json = flow.to_json
# {"type":"flowchart_diagram","version":1,"checksum":"...","data":{"title":"Deploy","nodes":[...],"edges":[...]}}

copy = Diagrams::Base.from_json(json)   # or Diagrams::FlowchartDiagram.from_h(flow.to_h)
copy == flow                            # => true: same type and content
copy.checksum == flow.checksum          # => true: SHA256 of the content

copy.add_node(id: 'rollback', label: 'Roll back')
flow.diff(copy)
# => {nodes: {added: [#<data Diagrams::Elements::Node id="rollback", label="Roll back">]}}
```

`version` is yours to manage; it is serialized but is not part of the content,
the checksum or equality. Loading a hash whose checksum does not match its
content raises `ArgumentError`. Equality is strict (`1` and `1.0` differ, as
they do in the JSON). `diff` matches elements by key (id, name, label or
title) and reports `added`, `removed` and `modified` per collection; elements
without a key (edges, transitions, relationships) match by value and count.

## Development

```bash
bundle install
bundle exec rake        # tests (padded_cell on CRuby) and RuboCop
bundle exec rake minitest
```

## License

MIT.
