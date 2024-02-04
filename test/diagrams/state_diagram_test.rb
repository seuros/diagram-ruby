# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class StateDiagramTest < DiagramTest
    def test_initialize
      states = create_states
      diagram = create_state_diagram(states:)

      assert_equal 'State Diagram', diagram.title
      assert_equal 2, diagram.states.size
    end

    def test_to_json
      states = create_states
      diagram = create_state_diagram(states:)

      expected = {
        id: '1',
        title: 'State Diagram',
        type: 'state_machine',
        states:,
        transitions: [],
        events: []
      }

      assert_equal expected, diagram.to_json
    end

    def test_from_json
      create_states
      diagram_json = deep_stringify_keys(
        {
          id: '1',
          title: 'State Diagram',
          type: 'state_machine'
        }
      )
      diag = StateDiagram.from_hash(diagram_json)

      assert_equal 'State Diagram', diag.title
    end

    def test_type
      assert_equal 'state_machine', create_state_diagram.type
    end

    def test_add_remove_state
      diagram = create_state_diagram
      state = diagram.add_state(id: '1', label: 'State 1')

      assert_equal 1, diagram.states.size
      assert_equal 'State 1', diagram.states.first.label
      assert_equal state, diagram.states.first

      diagram.remove_state('1')

      assert_equal 0, diagram.states.size
    end

    private

    def create_states
      [{
        id: '1',
        label: 'State 1'
      }, {
        id: '2',
        label: 'State 2'
      }]
    end

    def create_state_diagram(states: [], transitions: [], events: [])
      StateDiagram.new(
        id: '1',
        title: 'State Diagram',
        states:,
        transitions:,
        events:
      )
    end
  end
end
