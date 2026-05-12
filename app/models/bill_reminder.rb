class BillReminder < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  validates :name, presence: true
  validates :due_date, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :recurrence_period, inclusion: { in: %w[daily weekly monthly yearly], allow_nil: true, allow_blank: true }

  scope :pending, -> { where(paid: false).where("due_date >= ?", Date.today.beginning_of_month) }
  scope :overdue, -> { where(paid: false).where("due_date < ?", Date.today) }
  scope :upcoming, -> { where(paid: false).where(due_date: Date.today..1.week.from_now) }
  scope :this_month, -> { where(due_date: Date.today.beginning_of_month..Date.today.end_of_month) }
  scope :ordered, -> { order(due_date: :asc) }

  def overdue?
    !paid? && due_date < Date.today
  end

  def total_paid_this_month
    user.bill_reminders.this_month.where(paid: true).sum(:amount)
  end

  def total_pending_this_month
    user.bill_reminders.this_month.where(paid: false).sum(:amount)
  end
end
