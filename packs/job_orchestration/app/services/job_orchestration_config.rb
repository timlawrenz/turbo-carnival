class JobOrchestrationConfig
  # Per-parent breadth-first: each parent gets this many children
  # Creates balanced tree exploration: 2 → 4 → 8 → 16 → 32
  # Control growth by rejecting low-ELO candidates early
  def self.max_children_per_node
    ENV.fetch("MAX_CHILDREN_PER_NODE", "2").to_i
  end

  def self.target_leaf_nodes
    ENV.fetch("TARGET_LEAF_NODES", "10").to_i
  end
end
