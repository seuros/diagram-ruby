# frozen_string_literal: true

module Diagrams
  class FlowchartDiagram
    class Node < Dry::Struct
      attribute :id, FlowchartDiagram::Types::String
      attribute :label, FlowchartDiagram::Types::String

      def to_json(*_args)
        {
          id:,
          label:
        }
      end
    end
  end
end
