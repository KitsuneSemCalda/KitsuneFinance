class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :destination_account, class_name: "Account", optional: true
  belongs_to :category, optional: true
  belongs_to :goal, optional: true
  has_one_attached :receipt

  validates :description, presence: true
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense transfer] }
  validates :date, presence: true
  validate :destination_account_must_differ, if: :transfer?

  after_create :update_account_balance_on_create
  after_create :update_goal_progress_on_create
  after_destroy :update_account_balance_on_destroy
  after_destroy :update_destination_on_destroy
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

  def transfer?
    transaction_type == "transfer"
  end

  private

  def destination_account_must_differ
    if destination_account_id.blank?
      errors.add(:destination_account_id, "é obrigatória para transferências")
    elsif destination_account_id == account_id
      errors.add(:destination_account_id, "deve ser diferente da conta de origem")
    end
  end

  def update_account_balance_on_create
    if transfer? && destination_account
      account.decrement!(:balance, amount.abs)
      destination_account.increment!(:balance, amount.abs)
    else
      account.increment!(:balance, signed_amount)
    end
  end

  def update_account_balance_on_destroy
    account.decrement!(:balance, signed_amount)
  end

  def update_destination_on_destroy
    return unless transfer? && destination_account

    destination_account.decrement!(:balance, amount.abs)
  end

  def update_account_balance_on_update
    if saved_change_to_amount? || saved_change_to_transaction_type? || saved_change_to_account_id? || saved_change_to_destination_account_id?
      if transfer_was? && attribute_before_last_save(:destination_account_id)
        old_dest = Account.find(attribute_before_last_save(:destination_account_id))
        old_dest.decrement!(:balance, attribute_before_last_save(:amount).abs)
      end

      if transfer? && destination_account
        revert_old_account
        account.decrement!(:balance, amount.abs)
        destination_account.increment!(:balance, amount.abs)
      else
        default_balance_update
      end
    end
  end

  def transfer_was?
    attribute_before_last_save(:transaction_type) == "transfer"
  end

  def revert_old_account
    return unless saved_change_to_account_id?

    old_acc = Account.find(attribute_before_last_save(:account_id))
    old_amt = attribute_before_last_save(:amount).abs
    if transfer_was?
      old_acc.increment!(:balance, old_amt)
    else
      old_signed = attribute_before_last_save(:transaction_type) == "income" ? old_amt : -old_amt
      old_acc.decrement!(:balance, old_signed)
    end
  end

  def default_balance_update
    old_signed = attribute_before_last_save(:transaction_type) == "income" ? attribute_before_last_save(:amount).abs : -attribute_before_last_save(:amount).abs
    diff = signed_amount - old_signed
    account.increment!(:balance, diff)
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
