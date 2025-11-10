class RecordVote < GLCommand::Callable
  requires :winner, :loser

  def call
    ActiveRecord::Base.transaction do
      winner_change = context.winner.calculate_elo_change(context.loser, true)
      loser_change = context.loser.calculate_elo_change(context.winner, false)

      context.winner.update!(elo_score: context.winner.elo_score + winner_change)
      context.loser.update!(elo_score: context.loser.elo_score + loser_change)
    end
  end

  def rollback
    # GLCommand handles transaction rollback automatically
  end
end
