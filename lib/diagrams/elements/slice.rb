# frozen_string_literal: true

module Diagrams
  module Elements
    # A pie chart slice: a label and a non-negative value.
    Slice = Data.define(:label, :value) do
      include Element

      def initialize(label:, value:)
        super(label: Check.string(label, :label), value: Check.non_negative(value, :value))
      end

      def key = label
    end
  end
end
