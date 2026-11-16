# frozen_string_literal: true

module Diagrams
  module Elements
    # A state in a state diagram.
    State = Data.define(:id, :label) do
      include Element

      def initialize(id:, label: nil)
        super(id: Check.string(id, :id), label: Check.optional_string(label, :label))
      end

      def key = id
    end
  end
end
