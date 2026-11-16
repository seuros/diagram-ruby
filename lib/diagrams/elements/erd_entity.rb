# frozen_string_literal: true

module Diagrams
  module Elements
    # An ER entity and its attributes (ERDAttribute or hashes of their members).
    ERDEntity = Data.define(:name, :attributes) do
      include Element

      def initialize(name:, attributes: [])
        attributes = Check.elements(attributes, :attributes, ERDAttribute)
        duplicate = attributes.map(&:name).tally.find { _2 > 1 }&.first
        raise ArgumentError, "attribute #{duplicate.inspect} appears twice" if duplicate

        super(name: Check.string(name, :name), attributes:)
      end

      def key = name
    end
  end
end
