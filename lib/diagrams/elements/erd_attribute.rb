# frozen_string_literal: true

module Diagrams
  module Elements
    # An entity attribute: type, name, keys (PK, FK, UK) and an optional comment.
    ERDAttribute = Data.define(:type, :name, :keys, :comment) do
      include Element

      def initialize(type:, name:, keys: [], comment: nil)
        super(
          type: Check.string(type, :type),
          name: Check.string(name, :name),
          keys: Check.list(keys, :keys).map { Check.symbol(it, :keys, ERDAttribute::KEYS) }.uniq.freeze,
          comment: Check.optional_string(comment, :comment)
        )
      end

      def key = name
    end

    ERDAttribute::KEYS = %i[PK FK UK].freeze
  end
end
