# frozen_string_literal: true

require 'test_helper'

class StateDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::StateDiagram.new(title: 'Door')
    @diagram.add_state(id: 'open', label: 'Open')
    @diagram.add_state(id: 'closed')
  end

  def test_transitions
    transition = @diagram.add_transition(source_state_id: 'open', target_state_id: 'closed', label: 'close',
                                         guard: 'unlocked', action: 'beep')

    assert_equal 'unlocked', transition.guard
    assert_equal [transition], @diagram.transitions
  end

  def test_transitions_need_both_states
    assert_error(ArgumentError, /no state "ajar"/) do
      @diagram.add_transition(source_state_id: 'open', target_state_id: 'ajar')
    end
  end

  def test_terminal_pseudo_state
    @diagram.add_transition(source_state_id: '*', target_state_id: 'open')
    @diagram.add_transition(source_state_id: 'closed', target_state_id: '*')

    assert_equal 2, @diagram.transitions.size
    assert_error(ArgumentError, /terminal pseudo-state/) { @diagram.add_state(id: '*') }
  end

  def test_duplicate_states_are_rejected
    assert_error(ArgumentError, /State "open" already exists/) { @diagram.add_state(id: 'open') }
  end

  def test_round_trip
    @diagram.add_transition(source_state_id: '*', target_state_id: 'open')
    @diagram.add_transition(source_state_id: 'open', target_state_id: 'closed', label: 'close')

    assert_equal 'Door', assert_round_trip(@diagram).title
  end
end
