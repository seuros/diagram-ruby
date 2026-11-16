# frozen_string_literal: true

module Diagrams
  module Elements
    # A branch: its head commit (nil until something is committed on it or
    # it is created at a head) and the lane +order+ Mermaid sorts by, a whole
    # number JavaScript holds exactly.
    GitBranch = Data.define(:name, :order, :head_commit_id) do
      include Element

      def initialize(name:, order: nil, head_commit_id: nil)
        super(
          name: Check.string(name, :name),
          order: order.nil? ? nil : Check.integer(order, :order),
          head_commit_id: Check.optional_string(head_commit_id, :head_commit_id)
        )
      end

      def key = name
    end
  end
end
