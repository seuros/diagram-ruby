# frozen_string_literal: true

require 'test_helper'

class GitgraphDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::GitgraphDiagram.new
  end

  def history
    @diagram.commit(id: 'C1', message: 'init')
    @diagram.branch(name: 'develop', order: 1)
    @diagram.commit(id: 'D1', tags: %w[v0.1 beta])
    @diagram.checkout(name: 'main')
    @diagram.commit(id: 'C2', type: :HIGHLIGHT)
    @diagram.merge(branch: 'develop', id: 'M1', type: :REVERSE)
    @diagram.checkout(name: 'develop')
    @diagram.cherry_pick(commit_id: 'C2')
    @diagram
  end

  def branch(name) = @diagram.branches.find { it.name == name }

  def commit(id) = @diagram.commits.find { it.id == id }

  def test_main_branch_exists_from_the_start
    assert_equal [Diagrams::Elements::GitBranch.new(name: 'main')], @diagram.branches
    assert_equal 'main', @diagram.current_branch
    assert_equal %w[trunk], Diagrams::GitgraphDiagram.new(main_branch: 'trunk').branches.map(&:name)
  end

  def test_commits_chain_on_their_branch
    history

    assert_empty commit('C1').parents
    assert_equal %w[C1], commit('D1').parents
    assert_equal 'develop', commit('D1').branch
    assert_equal %w[v0.1 beta], commit('D1').tags
    assert_equal 'init', commit('C1').message
    assert_equal 'M1', branch('main').head_commit_id
    assert_equal 1, branch('develop').order
  end

  def test_a_branch_starts_at_the_current_head_even_before_a_commit
    early = @diagram.branch(name: 'early')
    @diagram.commit(id: 'E1')

    assert_nil early.head_commit_id
    assert_empty commit('E1').parents
    assert_equal 'early', commit('E1').branch
  end

  def test_merge
    merge = history.commits.find { it.id == 'M1' }

    assert_equal :MERGE, merge.type
    assert_equal :REVERSE, merge.custom_type
    assert_equal %w[C2 D1], merge.parents
    assert_equal 'merged branch develop into main', merge.message
  end

  def test_cherry_pick_follows_mermaid
    pick = history.commits.last

    assert_equal :CHERRY_PICK, pick.type
    assert_equal %w[D1 C2], pick.parents
    assert_equal ['cherry-pick:C2'], pick.tags
    assert_equal 'cherry-picked  into develop', pick.message
  end

  def test_cherry_pick_of_a_merge_names_its_parent
    history
    @diagram.branch(name: 'release')
    @diagram.checkout(name: 'main')
    @diagram.commit(id: 'C3')
    @diagram.checkout(name: 'release')
    pick = @diagram.cherry_pick(commit_id: 'M1', parent: 'D1')

    assert_equal ['cherry-pick:M1|parent:D1'], pick.tags
    assert_equal ['custom'], @diagram.cherry_pick(commit_id: 'C3', tags: ['custom']).tags
  end

  def test_generated_ids
    @diagram.commit(id: 'commit-1')
    @diagram.commit

    assert_equal %w[commit-1 commit-2], @diagram.commits.map(&:id)
  end

  def test_statements_are_the_program
    history

    assert_equal [
      { command: :commit, id: 'C1', message: 'init', type: :NORMAL },
      { command: :branch, name: 'develop', order: 1 },
      { command: :commit, id: 'D1', tags: %w[v0.1 beta], type: :NORMAL },
      { command: :checkout, name: 'main' },
      { command: :commit, id: 'C2', type: :HIGHLIGHT },
      { command: :merge, branch: 'develop', id: 'M1', type: :REVERSE },
      { command: :checkout, name: 'develop' },
      { command: :cherry_pick, commit_id: 'C2' }
    ], @diagram.statements
  end

  def test_commit_and_branch_refusals
    history
    assert_error(ArgumentError, /Commit "C1" already exists/) { @diagram.commit(id: 'C1') }
    assert_error(ArgumentError, /GitBranch "develop" already exists/) { @diagram.branch(name: 'develop') }
    assert_error(ArgumentError, /no branch "nope"/) { @diagram.checkout(name: 'nope') }
    assert_error(ArgumentError, /type must be one of NORMAL, REVERSE, HIGHLIGHT/) { @diagram.commit(type: :MERGE) }
    assert_error(RangeError, /order must be >= 0/) { @diagram.branch(name: 'x', order: -1) }
    assert_error(TypeError, /order must be an Integer/) { @diagram.branch(name: 'x', order: '1') }
  end

  # Mermaid's merge refusals, in Mermaid's order.
  def test_merge_refusals
    @diagram.branch(name: 'empty')
    assert_error(ArgumentError, /"empty" into itself/) { @diagram.merge(branch: 'empty') }
    assert_error(ArgumentError, /branch "empty" has no commits/) { @diagram.merge(branch: 'main') }
    @diagram.checkout(name: 'main')
    @diagram.commit(id: 'A')
    assert_error(ArgumentError, /branch "empty" has no commits/) { @diagram.merge(branch: 'empty') }
    assert_error(ArgumentError, /no branch "nope"/) { @diagram.merge(branch: 'nope') }
    @diagram.branch(name: 'dev')
    assert_error(ArgumentError, /"main" into itself: its head is the head of "dev"/) { @diagram.merge(branch: 'main') }
    @diagram.commit(id: 'B')
    @diagram.checkout(name: 'main')
    assert_error(ArgumentError, /Commit "A" already exists/) { @diagram.merge(branch: 'dev', id: 'A') }
  end

  # Mermaid's cherry-pick refusals, plus: a cherry-pick cannot be named.
  def test_cherry_pick_refusals
    history
    assert_error(ArgumentError, /no commit "nope"/) { @diagram.cherry_pick(commit_id: 'nope') }
    assert_error(ArgumentError, /"C2" is not an immediate parent of "D1"/) do
      @diagram.cherry_pick(commit_id: 'D1', parent: 'C2')
    end
    @diagram.checkout(name: 'main')
    assert_error(ArgumentError, /"C2" is already on "main"/) do
      @diagram.cherry_pick(commit_id: 'C2')
    end
    @diagram.checkout(name: 'develop')
    assert_error(ArgumentError, /"M1" is a merge: name the parent/) { @diagram.cherry_pick(commit_id: 'M1') }
    pick = @diagram.commits.last.id
    @diagram.checkout(name: 'main')
    assert_error(ArgumentError, /is a cherry-pick, which Mermaid cannot name, so it cannot be picked/) do
      @diagram.cherry_pick(commit_id: pick)
    end
  end

  def test_a_cherry_pick_cannot_be_named_as_parent
    history
    @diagram.checkout(name: 'main')
    @diagram.merge(branch: 'develop', id: 'M2')
    @diagram.branch(name: 'other')
    @diagram.checkout(name: 'develop')
    @diagram.commit(id: 'D2')
    @diagram.checkout(name: 'other')
    pick = commit('M2').parents.last

    assert_error(ArgumentError, /is a cherry-pick, which Mermaid cannot name as a parent/) do
      @diagram.cherry_pick(commit_id: 'M2', parent: pick)
    end
  end

  def test_cherry_pick_needs_a_commit_on_the_current_branch
    @diagram.branch(name: 'empty')
    @diagram.checkout(name: 'main')
    @diagram.commit(id: 'A')
    @diagram.checkout(name: 'empty')

    assert_error(ArgumentError, /branch "empty" has no commits/) { @diagram.cherry_pick(commit_id: 'A') }
  end

  def test_a_refusal_changes_nothing
    history
    before = [@diagram.to_h, @diagram.current_branch]
    assert_raises(ArgumentError) { @diagram.cherry_pick(commit_id: 'M1') }
    assert_raises(ArgumentError) { @diagram.merge(branch: 'develop', id: 'C1') }

    assert_equal before, [@diagram.to_h, @diagram.current_branch]
  end

  def test_round_trip_replays_the_statements
    loaded = assert_round_trip(history)

    assert_equal 'develop', loaded.current_branch
    assert_equal @diagram.commits, loaded.commits
    assert_equal @diagram.branches, loaded.branches
  end

  def test_round_trip_of_an_empty_graph
    assert_round_trip(@diagram)
  end

  def test_from_h_takes_a_hand_written_program
    loaded = Diagrams::GitgraphDiagram.from_h(
      type: 'gitgraph_diagram',
      data: { statements: [{ command: 'commit', id: 'A' }, { command: 'branch', name: 'dev' },
                           { command: 'commit' }] }
    )

    assert_equal %w[A commit-1], loaded.commits.map(&:id)
    assert_equal 'dev', loaded.current_branch
  end

  def test_from_h_refuses_what_mermaid_refuses
    hash = { type: 'gitgraph_diagram', data: { statements: [{ command: 'merge', branch: 'main' }] } }

    assert_error(ArgumentError, /"main" into itself/) { Diagrams::Base.from_h(hash) }
    assert_error(ArgumentError, /command must be one of/) do
      Diagrams::Base.from_h(type: 'gitgraph_diagram', data: { statements: [{ command: 'rebase' }] })
    end
  end
end
