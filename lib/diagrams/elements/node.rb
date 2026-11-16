# frozen_string_literal: true

module Diagrams
  module Elements
    # A flowchart node.
    Node = Data.define(:id, :label) do
      include Element

      def initialize(id:, label:)
        super(id: Check.string(id, :id), label: Check.string(label, :label))
      end

      def key = id
    end
  end
end
