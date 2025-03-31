# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class StateDiagramTest < DiagramTest
    def setup
      @state1 = Elements::State.new(id: 's1', label: 'Idle')
      @state2 = Elements::State.new(id: 's2', label: 'Running')
      @state3 = Elements::State.new(id: 's3', label: 'Stopped')
      @event1 = Elements::Event.new(id: 'e1', label: 'start')
      @event2 = Elements::Event.new(id: 'e2', label: 'stop')
      @trans1 = Elements::Transition.new(source_state_id: 's1', target_state_id: 's2', label: 'start_event') # Label might link to event
      @trans2 = Elements::Transition.new(source_state_id: 's2', target_state_id: 's3', label: 'stop_event')
    end

    def test_initialize_empty
      diagram = StateDiagram.new

      assert_equal '', diagram.title
      assert_empty diagram.states
      assert_empty diagram.transitions
      assert_empty diagram.events
      assert_equal 1, diagram.version
      refute_nil diagram.checksum
    end

    def test_initialize_with_elements
      diagram = StateDiagram.new(title: 'Machine', states: [@state1, @state2], transitions: [@trans1],
                                 events: [@event1], version: 'v1')

      assert_equal 'Machine', diagram.title
      assert_equal [@state1, @state2], diagram.states
      assert_equal [@trans1], diagram.transitions
      assert_equal [@event1], diagram.events
      assert_equal 'v1', diagram.version
    end

    def test_initialize_validates_duplicate_state_id
      error = assert_raises(ArgumentError) do
        StateDiagram.new(states: [@state1, @state1])
      end
      assert_match(/Duplicate state IDs found/, error.message)
    end

    def test_initialize_validates_duplicate_event_id
      error = assert_raises(ArgumentError) do
        StateDiagram.new(events: [@event1, @event1])
      end
      assert_match(/Duplicate event IDs found/, error.message)
    end

    def test_initialize_validates_transition_states
      error = assert_raises(ArgumentError) do
        StateDiagram.new(states: [@state1], transitions: [@trans1]) # trans1 needs s2
      end
      assert_match(/Transition refers to non-existent state IDs/, error.message)
    end

    def test_add_state
      diagram = StateDiagram.new
      initial_checksum = diagram.checksum
      diagram.add_state(@state1)

      assert_equal [@state1], diagram.states
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_state_duplicate_id
      diagram = StateDiagram.new(states: [@state1])
      error = assert_raises(ArgumentError) do
        diagram.add_state(@state1)
      end
      assert_match(/State with ID 's1' already exists/, error.message)
    end

    def test_add_transition
      diagram = StateDiagram.new(states: [@state1, @state2])
      initial_checksum = diagram.checksum
      diagram.add_transition(@trans1)

      assert_equal [@trans1], diagram.transitions
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_transition_invalid_state
      diagram = StateDiagram.new(states: [@state1]) # Missing state s2
      error = assert_raises(ArgumentError) do
        diagram.add_transition(@trans1)
      end
      assert_match(/Transition refers to non-existent state IDs/, error.message)
    end

    def test_add_event
      diagram = StateDiagram.new
      initial_checksum = diagram.checksum
      diagram.add_event(@event1)

      assert_equal [@event1], diagram.events
      refute_equal initial_checksum, diagram.checksum
    end

    def test_add_event_duplicate_id
      diagram = StateDiagram.new(events: [@event1])
      error = assert_raises(ArgumentError) do
        diagram.add_event(@event1)
      end
      assert_match(/Event with ID 'e1' already exists/, error.message)
    end

    def test_find_state
      diagram = StateDiagram.new(states: [@state1, @state2])

      assert_equal @state1, diagram.find_state('s1')
      assert_nil diagram.find_state('s_invalid')
    end

    def test_find_event
      diagram = StateDiagram.new(events: [@event1, @event2])

      assert_equal @event1, diagram.find_event('e1')
      assert_nil diagram.find_event('e_invalid')
    end

    def test_to_h_content
      diagram = StateDiagram.new(title: 'Simple State', states: [@state1], transitions: [], events: [])
      expected = {
        title: 'Simple State',
        states: [@state1.to_h],
        transitions: [],
        events: []
      }

      assert_equal expected, diagram.to_h_content
    end

    def test_to_h
      diagram = StateDiagram.new(title: 'State v9', states: [@state1], version: 9)
      expected = {
        type: 'state_diagram',
        version: 9,
        checksum: diagram.checksum,
        data: {
          title: 'State v9',
          states: [@state1.to_h],
          transitions: [],
          events: []
        }
      }

      assert_equal expected, diagram.to_h
    end

    def test_serialization_deserialization
      diagram1 = StateDiagram.new(title: 'Process', states: [@state1, @state2], transitions: [@trans1],
                                  events: [@event1], version: 'v0.1')
      json_data = diagram1.to_json
      diagram2 = Base.from_json(json_data) # Use Base factory

      assert_instance_of StateDiagram, diagram2
      assert_equal diagram1.version, diagram2.version
      assert_equal diagram1.title, diagram2.title
      # Compare content via checksum (equality uses checksum)
      assert_equal diagram1, diagram2
      # Explicit content check
      assert_equal diagram1.states.map(&:to_h), diagram2.states.map(&:to_h)
      assert_equal diagram1.transitions.map(&:to_h), diagram2.transitions.map(&:to_h)
      assert_equal diagram1.events.map(&:to_h), diagram2.events.map(&:to_h)
    end

    def test_equality
      # Ensure all required states for transitions are present at initialization
      diagram1 = StateDiagram.new(states: [@state1, @state2], transitions: [@trans1])
      diagram2 = StateDiagram.new(states: [Elements::State.new(id: 's1', label: 'Idle'), @state2],
                                  transitions: [Elements::Transition.new(
                                    source_state_id: 's1', target_state_id: 's2', label: 'start_event'
                                  )])
      diagram3 = StateDiagram.new(states: [@state1, @state2, @state3], transitions: [@trans1]) # Add s3 to make it different
      diagram4 = StateDiagram.new(states: [@state1, @state2], transitions: [@trans1], version: 2) # Different version
      diagram5 = StateDiagram.new(title: 'Different', states: [@state1, @state2], transitions: [@trans1]) # Different title

      # diagram2.add_state(@state2) # No longer needed as s2 is added during init

      assert_equal diagram1, diagram2 # Same content
      refute_equal diagram1, diagram3 # Different states
      assert_equal diagram1, diagram4 # Same content, different version
      refute_equal diagram1, diagram5 # Different title
    end
  end
end
