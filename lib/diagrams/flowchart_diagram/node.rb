# frozen_string_literal: true

module Diagrams
  class FlowchartDiagram
    class Node < Dry::Struct
      attribute :id, FlowchartDiagram::Types::String
      attribute :label, FlowchartDiagram::Types::String
    end
  end
end
