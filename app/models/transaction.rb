class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :goal, optional: true

  validates :description, presence: true
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense transfer] }
  validates :date, presence: true

  after_create :update_account_balance_on_create
  after_create :update_goal_progress_on_create
  after_destroy :update_account_balance_on_destroy
  after_destroy :update_goal_progress_on_destroy
  after_update :update_account_balance_on_update
  after_update :update_goal_progress_on_update

  scope :income, -> { where(transaction_type: "income") }
  scope :expense, -> { where(transaction_type: "expense") }
  scope :current_month, -> { where(date: Date.today.beginning_of_month..Date.today.end_of_month) }
  scope :recent, -> { order(date: :desc, created_at: :desc).limit(10) }

  def signed_amount
    transaction_type == "income" ? amount.abs : -amount.abs
  end

  private

  def update_account_balance_on_create
    account.increment!(:balance, signed_amount)
  end

  def update_account_balance_on_destroy
    account.decrement!(:balance, signed_amount)
  end

  def update_account_balance_on_update
    if saved_change_to_amount? || saved_change_to_transaction_type? || saved_change_to_account_id?
      if saved_change_to_account_id?
        # Revert old account
        old_account = Account.find(attribute_before_last_save(:account_id))
        old_signed_amount = attribute_before_last_save(:transaction_type) == "income" ? attribute_before_last_save(:amount).abs : -attribute_before_last_save(:amount).abs
        old_account.decrement!(:balance, old_signed_amount)
        
        # Update new account
        account.increment!(:balance, signed_amount)
      else
        old_signed_amount = attribute_before_last_save(:transaction_type) == "income" ? attribute_before_last_save(:amount).abs : -attribute_before_last_save(:amount).abs
        diff = signed_amount - old_signed_amount
        account.increment!(:balance, diff)
      end
    end
  end

  def update_goal_progress_on_create
    return unless goal
    # Expense on goal increases goal amount, income decreases it (refund)
    goal_diff = (transaction_type == "expense" ? amount.abs : -amount.abs)
    goal.increment!(:current_amount, goal_diff)
  end

  def update_goal_progress_on_destroy
    return unless goal
    goal_diff = (transaction_type == "expense" ? amount.abs : -amount.abs)
    goal.decrement!(:current_amount, goal_diff)
  end

  def update_goal_progress_on_update
    if saved_change_to_amount? || saved_change_to_transaction_type? || saved_change_to_goal_id?
      if saved_change_to_goal_id?
        # Revert old goal
        if attribute_before_last_save(:goal_id)
          old_goal = Goal.find(attribute_before_last_save(:goal_id))
          old_diff = attribute_before_last_save(:transaction_type) == "expense" ? attribute_before_last_save(:amount).abs : -attribute_before_last_save(:amount).abs
          old_goal.decrement!(:current_amount, old_diff)
        end
        
        # Update new goal
        update_goal_progress_on_create
      else
        return unless goal
        old_diff = attribute_before_last_save(:transaction_type) == "expense" ? attribute_before_last_save(:amount).abs : -attribute_before_last_save(:amount).abs
        new_diff = (transaction_type == "expense" ? amount.abs : -amount.abs)
        diff = new_diff - old_diff
        goal.increment!(:current_amount, diff)
      end
    end
  end
end
