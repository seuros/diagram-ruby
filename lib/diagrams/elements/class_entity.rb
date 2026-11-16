# frozen_string_literal: true

module Diagrams
  module Elements
    # A class in a class diagram, with its attributes and operations as
    # display strings ("+String name", "+save() bool").
    ClassEntity = Data.define(:name, :attributes, :operations) do
      include Element

      def initialize(name:, attributes: [], operations: [])
        super(
          name: Check.string(name, :name),
          attributes: Check.strings(attributes, :attributes),
          operations: Check.strings(operations, :operations)
        )
      end

      def key = name
    end
  end
end
