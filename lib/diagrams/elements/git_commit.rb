# frozen_string_literal: true

module Diagrams
  module Elements
    # A commit as Mermaid's gitGraph records it: made on +branch+, with
    # +parents+ (the branch's previous head first; a merge or cherry-pick has
    # the merged head or picked commit second), +tags+ and a +type+. A merge
    # may carry the display type it was given as +custom_type+.
    GitCommit = Data.define(:id, :branch, :parents, :message, :tags, :type, :custom_type) do
      include Element

      def initialize(id:, branch:, parents: [], message: nil, tags: [], type: :NORMAL, custom_type: nil)
        super(
          id: Check.string(id, :id),
          branch: Check.string(branch, :branch),
          parents: Check.strings(parents, :parents),
          message: Check.optional_string(message, :message),
          tags: Check.strings(tags, :tags),
          type: Check.symbol(type, :type, GitCommit::TYPES),
          custom_type: custom_type.nil? ? nil : Check.symbol(custom_type, :custom_type, GitCommit::DISPLAY_TYPES)
        )
      end

      def key = id
    end

    GitCommit::DISPLAY_TYPES = %i[NORMAL REVERSE HIGHLIGHT].freeze
    GitCommit::TYPES = [*GitCommit::DISPLAY_TYPES, :MERGE, :CHERRY_PICK].freeze
  end
end
