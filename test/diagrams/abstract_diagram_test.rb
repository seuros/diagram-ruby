# frozen_string_literal: true

require 'test_helper'

module Diagrams
  class AbstractDiagramTest < Minitest::Test
    def test_initialize
      assert_raises NotImplementedError do
        AbstractDiagram.new
      end
    end

    def test_type
      klass = Class.new(AbstractDiagram)
      instance = klass.new
      assert_raises NotImplementedError do
        instance.type
      end
    end
  end
end
