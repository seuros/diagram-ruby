# frozen_string_literal: true

require 'diagram'
require 'minitest/autorun'

# Assertions shared by the diagram tests.
module DiagramAssertions
  # The diagram survives JSON and comes back equal, with the same checksum.
  def assert_round_trip(diagram)
    loaded = Diagrams::Base.from_json(diagram.to_json)

    assert_equal diagram, loaded
    assert_equal diagram.checksum, loaded.checksum
    loaded
  end

  def assert_error(type, pattern, &)
    error = assert_raises(type, &)

    assert_match pattern, error.message
  end
end

Minitest::Test.include(DiagramAssertions)
