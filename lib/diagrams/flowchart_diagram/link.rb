# frozen_string_literal: true

module Diagrams
  class FlowchartDiagram
    class Link < Dry::Struct
      attribute :from, FlowchartDiagram::Types::String
      attribute :to, FlowchartDiagram::Types::String
      attribute :label, FlowchartDiagram::Types::String.optional.default(nil)
    end
  end
end
