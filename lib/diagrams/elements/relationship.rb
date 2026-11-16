# frozen_string_literal: true

module Diagrams
  module Elements
    # A relationship between two classes in a class diagram.
    Relationship = Data.define(:source_class_name, :target_class_name, :type, :label) do
      include Element

      def initialize(source_class_name:, target_class_name:, type:, label: nil)
        super(
          source_class_name: Check.string(source_class_name, :source_class_name),
          target_class_name: Check.string(target_class_name, :target_class_name),
          type: Check.symbol(type, :type, Relationship::TYPES),
          label: Check.optional_string(label, :label)
        )
      end
    end

    Relationship::TYPES = %i[inheritance composition aggregation association dependency realization link].freeze
  end
end
