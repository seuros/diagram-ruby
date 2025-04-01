# Gitgraph Diagram (`Diagrams::GitgraphDiagram`)

This diagram type represents the history of a Git repository, including commits, branches, merges, and cherry-picks. It allows for modeling Git workflows and structures programmatically.

## Usage Example

The following example demonstrates creating a simple Git history, serializing it to a hash, and then deserializing it back into a diagram object.

```ruby
require 'diagrams' # Assuming the gem is loaded

# 1. Create a new Gitgraph diagram
diagram = Diagrams::GitgraphDiagram.new(version: '1.1')

# 2. Add commits and branches
c1 = diagram.commit(id: 'C1', message: 'Initial commit')
diagram.branch(name: 'develop') # Creates 'develop' and checks it out
c2 = diagram.commit(id: 'D1', message: 'Feature work on develop')
diagram.checkout(name: 'master')
c3 = diagram.commit(id: 'C2', message: 'Hotfix on master')
merge_commit = diagram.merge(from_branch_name: 'develop', id: 'M1', tag: 'v1.0-merge')
c4 = diagram.commit(id: 'C3', message: 'Post-merge commit')

# 3. Serialize to Hash
diagram_hash = diagram.to_h
puts "Serialized Hash:"
pp diagram_hash
# Output will be a hash like:
# {:type=>"gitgraph_diagram",
#  :version=>"1.1",
#  :checksum=>"...",
#  :data=>
#   {:commits=>
#     [{:id=>"C1", :parent_ids=>[], :branch_name=>"master", :type=>:NORMAL, :message=>"Initial commit"},
#      {:id=>"D1", :parent_ids=>["C1"], :branch_name=>"develop", :type=>:NORMAL, :message=>"Feature work on develop"},
#      {:id=>"C2", :parent_ids=>["C1"], :branch_name=>"master", :type=>:NORMAL, :message=>"Hotfix on master"},
#      {:id=>"M1", :parent_ids=>["C2", "D1"], :branch_name=>"master", :type=>:MERGE, :tag=>"v1.0-merge", :message=>"Merge branch 'develop' into master"},
#      {:id=>"C3", :parent_ids=>["M1"], :branch_name=>"master", :type=>:NORMAL, :message=>"Post-merge commit"}],
#    :branches=>
#     [{:name=>"master", :start_commit_id=>"C1", :head_commit_id=>"C3"},
#      {:name=>"develop", :start_commit_id=>"C1", :head_commit_id=>"D1"}],
#    :commit_order=>["C1", "D1", "C2", "M1", "C3"],
#    :current_branch_name=>"master"}}


# 4. Deserialize from Hash
reloaded_diagram = Diagrams::Base.from_hash(diagram_hash)

# 5. Verify
puts "\nVerification:"
puts "Reloaded diagram class: #{reloaded_diagram.class}"
puts "Original checksum:   #{diagram.checksum}"
puts "Reloaded checksum:   #{reloaded_diagram.checksum}"
puts "Checksums match?     #{diagram.checksum == reloaded_diagram.checksum}"
puts "Diagrams equal?      #{diagram == reloaded_diagram}" # Uses checksum and class for equality

# Access data from reloaded diagram
puts "Reloaded commit M1 tag: #{reloaded_diagram.commits['M1'].tag}"
puts "Reloaded master head:   #{reloaded_diagram.branches['master'].head_commit_id}"

```

This demonstrates the basic workflow of creating, manipulating, serializing, and deserializing `GitgraphDiagram` objects. The `Diagrams::Base.from_json` method can be used similarly if you have a JSON string representation.