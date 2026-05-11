class SnapshotBalanceJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      total_balance = user.accounts.sum(:balance)
      total_investments = user.investments.sum { |i| i.current_value }
      net_worth = total_balance + total_investments

      snapshot = user.balance_snapshots.find_or_initialize_by(snapshot_date: Date.today)
      snapshot.update!(
        total_balance: total_balance,
        total_investments: total_investments,
        net_worth: net_worth
      )
    end
  end
end
