class RejectImageBranch < GLCommand::Callable
  requires :image_candidate

  returns :parent_navigation

  def call
    context.image_candidate.reject!

    # Prepare parent navigation data for kill-left workflow
    context.parent_navigation = context.image_candidate.parent_with_sibling
  end

  def rollback
    # GLCommand handles transaction rollback automatically
  end
end
