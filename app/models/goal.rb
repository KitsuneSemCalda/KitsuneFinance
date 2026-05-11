class Goal < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify

  validates :name, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :current_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active completed paused] }

  before_save :check_status

  def progress_pct
    return 100 if target_amount.zero?
    [((current_amount.to_f / target_amount) * 100).to_f, 100.0].min
  end

  def completed?
    current_amount >= target_amount
  end

  private

  def check_status
    self.status = "completed" if completed? && status == "active"
  end
end
