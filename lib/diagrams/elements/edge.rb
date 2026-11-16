# frozen_string_literal: true

module Diagrams
  module Elements
    # A directed flowchart edge between two nodes.
    Edge = Data.define(:source_id, :target_id, :label) do
      include Element

      def initialize(source_id:, target_id:, label: nil)
        super(
          source_id: Check.string(source_id, :source_id),
          target_id: Check.string(target_id, :target_id),
          label: Check.optional_string(label, :label)
        )
      end
    end
  end
end
