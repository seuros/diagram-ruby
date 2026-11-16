# frozen_string_literal: true

module Diagrams
  # A git graph as Mermaid's gitGraph builds it: a program of statements
  # (commit, branch, checkout, merge, cherry_pick), each checked and applied
  # the way Mermaid applies it, with the same refusals. The statements are
  # the content; commits and branches are what they produce.
  #
  # Like Mermaid, the main branch exists from the start, a branch starts at
  # the current head (even before the first commit), and a cherry-pick gets
  # an id the program cannot name: here it is generated, never written to
  # Mermaid, and a cherry-pick is therefore never picked or named as a
  # parent.
  class GitgraphDiagram < Base
    include Refusals

    COMMANDS = %i[commit branch checkout merge cherry_pick].freeze

    collection :commits
    collection :branches

    attr_reader :main_branch, :current_branch, :statements

    def initialize(main_branch: 'main', **)
      super(**)
      @main_branch = Check.string(main_branch, :main_branch)
      @current_branch = @main_branch
      @statements = [].freeze
      append(:branches, Elements::GitBranch.new(name: @main_branch))
    end

    # Mermaid: commit id: msg: tag: type:
    def commit(id: nil, message: nil, tags: [], type: :NORMAL)
      type = Check.symbol(type, :type, Elements::GitCommit::DISPLAY_TYPES)
      tags = Check.strings(tags, :tags)
      commit = add_commit(id:, message:, tags:, type:, parents: [head_id].compact)
      record(command: :commit, id: commit.id, message:, tags:, type:)
      commit
    end

    # Mermaid: branch <name> order: — at the current head, then checked out.
    def branch(name:, order: nil)
      branch = append(:branches, Elements::GitBranch.new(name:, order:, head_commit_id: head_id))
      @current_branch = branch.name
      record(command: :branch, name:, order:)
      branch
    end

    # Mermaid: checkout <name> (or its synonym, switch).
    def checkout(name:)
      branch = find!(:branches, name, 'branch')
      @current_branch = branch.name
      record(command: :checkout, name:)
      branch
    end

    # Mermaid: merge <branch> id: tag: type: — refusals in Mermaid's order.
    def merge(branch:, id: nil, tags: [], type: nil)
      Check.string(branch, :branch)
      tags = Check.strings(tags, :tags)
      type = Check.symbol(type, :type, Elements::GitCommit::DISPLAY_TYPES) unless type.nil?
      current = commit_at(head_id)
      other = commit_at(branches.find { it.name == branch }&.head_commit_id)
      refuse_merge(branch, current, other)

      commit = add_commit(id:, tags:, type: :MERGE, custom_type: type, parents: [current.id, other.id],
                          message: "merged branch #{branch} into #{current_branch}")
      record(command: :merge, branch:, id: commit.id, tags:, type:)
      commit
    end

    # Mermaid: cherry-pick id: parent: tag: — copies +commit_id+ onto the
    # current branch. A merge needs the +parent+ to pick from. Without tags
    # the commit is tagged "cherry-pick:<id>" (and "|parent:<parent>" for a
    # merge), as Mermaid tags it.
    def cherry_pick(commit_id:, parent: nil, tags: [])
      source = find!(:commits, commit_id, 'commit')
      tags = Check.strings(tags, :tags)
      refuse_cherry_pick(source, parent)

      default = "cherry-pick:#{source.id}#{"|parent:#{parent}" if source.type == :MERGE}"
      message = "cherry-picked #{source.message} into #{current_branch}"
      commit = add_commit(id: nil, tags: tags.empty? ? [default] : tags, type: :CHERRY_PICK,
                          parents: [head_id, source.id], message:)
      record(command: :cherry_pick, commit_id:, parent:, tags:)
      commit
    end

    # The statements as plain data, in order: the program Mermaid runs.
    def content = { **settings, statements: statements.map(&:dup) }.compact

    class << self
      private

      # Runs the recorded statements again, through the same checks.
      def restore(data, version:)
        new(version:, **data.except(:statements)).tap do |diagram|
          Check.list(data.fetch(:statements, []), :statements).each do |statement|
            statement = Check.record(statement, :statements)
            command = Check.symbol(statement[:command], :command, COMMANDS)
            diagram.public_send(command, **statement.except(:command))
          end
        end
      end
    end

    private

    def settings = { **super, main_branch: }

    def record(**statement)
      statement = statement.reject { |_, value| value.nil? || value == [] }.freeze
      @statements = [*@statements, statement].freeze
    end

    def head_id = branches.find { it.name == current_branch }.head_commit_id

    def commit_at(id) = id && commits.find { it.id == id }

    def add_commit(id:, **)
      commit = append(:commits, Elements::GitCommit.new(id: id.nil? ? next_id : id, branch: current_branch, **))
      current = branches.find { it.name == current_branch }
      replace(:branches, current, current.with(head_commit_id: commit.id))
      commit
    end

    def next_id
      number = commits.size
      number += 1 while commits.any? { it.id == "commit-#{number}" }
      "commit-#{number}"
    end
  end
end
