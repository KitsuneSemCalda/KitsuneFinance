class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true
  validates :limit_amount, presence: true, numericality: { greater_than: 0 }

  def spent_amount
    user.transactions
        .expense
        .where(category_id: category_id)
        .where(date: Date.new(year, month, 1)..Date.new(year, month, -1))
        .sum(:amount)
  end

  def remaining_amount
    [limit_amount - spent_amount, 0].max
  end

  def progress_pct
    return 0 if limit_amount.zero?
    [((spent_amount / limit_amount) * 100).to_f, 100.0].min
  end

  def over_budget?
    spent_amount > limit_amount
  end
end
