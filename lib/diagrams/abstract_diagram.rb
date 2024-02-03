# frozen_string_literal: true

module Diagrams
  # Abstract class for diagrams
  class AbstractDiagram < Dry::Struct
    module Types
      include Dry.Types()
    end

    def initialize(*)
      raise NotImplementedError, 'Cannot instantiate abstract class' if instance_of?(AbstractDiagram)

      super
    end

    def type
      raise NotImplementedError, 'Subclasses must define `type`.'
    end

    ## Errors
    class ValidationError < StandardError; end
    class EmptyDiagramError < ValidationError; end
    class InvalidPercentageError < ValidationError; end
    class DuplicateLabelError < ValidationError; end
  end
end
