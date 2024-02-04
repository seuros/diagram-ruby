# frozen_string_literal: true

module Diagrams
  class FlowchartDiagram
    class Link < Dry::Struct
      attribute :id, FlowchartDiagram::Types::String
      attribute :from, FlowchartDiagram::Types::String
      attribute :to, FlowchartDiagram::Types::String
      attribute :label, FlowchartDiagram::Types::String.optional.default(nil)

      def to_json(*_args)
        {
          id:,
          from:,
          to:,
          label:
        }
      end
    end
  end
end
