class JobOrchestrationConfig
  def self.max_children_per_node
    ENV.fetch("MAX_CHILDREN_PER_NODE", "5").to_i
  end

  def self.target_leaf_nodes
    ENV.fetch("TARGET_LEAF_NODES", "10").to_i
  end
end
