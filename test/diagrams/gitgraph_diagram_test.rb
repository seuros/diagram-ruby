# frozen_string_literal: true

require 'test_helper'

class GitgraphDiagramTest < Minitest::Test
  def setup
    @diagram = Diagrams::GitgraphDiagram.new
  end

  def history
    @diagram.commit(id: 'C1', message: 'init')
    @diagram.branch(name: 'develop')
    @diagram.commit(id: 'D1', tag: 'v0.1')
    @diagram.branch(name: 'idle')
    @diagram.checkout(name: 'main')
    @diagram.commit(id: 'C2', type: :HIGHLIGHT)
    @diagram.merge(from_branch_name: 'develop', id: 'M1')
    @diagram.checkout(name: 'develop')
    @diagram.cherry_pick(commit_id: 'C2', id: 'P1')
    @diagram
  end

  def branch(name) = @diagram.branches.find { it.name == name }

  def commit(id) = @diagram.commits.find { it.id == id }

  def test_first_commit_creates_the_main_branch
    @diagram.commit(id: 'C1')

    assert_equal [Diagrams::Elements::GitBranch.new(name: 'main', start_commit_id: 'C1')], @diagram.branches
    assert_empty commit('C1').parent_ids
  end

  def test_main_branch_name
    diagram = Diagrams::GitgraphDiagram.new(main_branch: 'trunk')
    diagram.commit

    assert_equal %w[trunk], diagram.branches.map(&:name)
  end

  def test_commits_chain_on_their_branch
    history

    assert_equal %w[C1], commit('D1').parent_ids
    assert_equal 'develop', commit('D1').branch_name
    assert_equal 'P1', branch('develop').head_commit_id
    assert_equal 'M1', branch('main').head_commit_id
    assert_equal 'D1', branch('idle').head_commit_id
  end

  def test_merge
    merge = history.commits.find { it.id == 'M1' }

    assert_equal :MERGE, merge.type
    assert_equal %w[C2 D1], merge.parent_ids
    assert_equal 'develop', merge.merge_branch_name
    assert_equal "Merge branch 'develop' into main", merge.message
  end

  def test_cherry_pick
    pick = history.commits.find { it.id == 'P1' }

    assert_equal :CHERRY_PICK, pick.type
    assert_equal 'C2', pick.cherry_pick_source_id
    assert_equal %w[D1], pick.parent_ids
  end

  def test_generated_ids
    @diagram.commit(id: 'commit-1')
    @diagram.commit

    assert_equal %w[commit-1 commit-2], @diagram.commits.map(&:id)
  end

  def test_errors
    assert_error(ArgumentError, /cannot branch before the first commit/) { @diagram.branch(name: 'x') }
    history
    assert_error(ArgumentError, /Commit "C1" already exists/) { @diagram.commit(id: 'C1') }
    assert_error(ArgumentError, /GitBranch "develop" already exists/) { @diagram.branch(name: 'develop') }
    assert_error(ArgumentError, /no commit "nope"/) { @diagram.branch(name: 'x', start_commit_id: 'nope') }
    assert_error(ArgumentError, /no branch "nope"/) { @diagram.checkout(name: 'nope') }
    assert_error(ArgumentError, /no branch "nope"/) { @diagram.merge(from_branch_name: 'nope') }
    assert_error(ArgumentError, /into itself/) { @diagram.merge(from_branch_name: 'develop') }
    assert_error(ArgumentError, /already on "develop"/) { @diagram.cherry_pick(commit_id: 'D1') }
    assert_error(ArgumentError, /cannot cherry-pick merge commit "M1"/) { @diagram.cherry_pick(commit_id: 'M1') }
    assert_error(ArgumentError, /type must be one of NORMAL, REVERSE, HIGHLIGHT/) { @diagram.commit(type: :MERGE) }
  end

  def test_round_trip_replays_the_history
    loaded = assert_round_trip(history)

    assert_equal 'main', loaded.current_branch_name
    assert_equal @diagram.branches, loaded.branches
  end

  def test_round_trip_of_an_empty_graph
    assert_round_trip(@diagram)
  end

  def test_from_h_takes_a_hand_written_history
    loaded = Diagrams::GitgraphDiagram.from_h(
      type: 'gitgraph_diagram',
      data: { commits: [{ id: 'A', branch_name: 'main' }],
              branches: [{ name: 'main', start_commit_id: 'A' }] }
    )

    assert_equal %w[A], loaded.commits.map(&:id)
  end

  def test_from_h_rejects_a_branch_from_an_unknown_commit
    hash = history.to_h.except(:checksum)
    hash[:data][:branches] << { name: 'lost', start_commit_id: 'nope' }

    assert_error(ArgumentError, /branch "lost" starts at no known commit/) { Diagrams::Base.from_h(hash) }
  end

  def test_from_h_rejects_a_history_that_does_not_replay
    hash = history.to_h.except(:checksum)
    hash[:data][:commits][1][:parent_ids] = []

    assert_error(ArgumentError, /do not replay/) { Diagrams::Base.from_h(hash) }
  end
end
