class Debt < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :monthly_payment, presence: true, numericality: { greater_than: 0 }
  validates :installments_count, presence: true, numericality: { greater_than: 0 }
  validates :remaining_installments, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def total_remaining
    remaining_installments * monthly_payment
  end

  def progress_pct
    return 100 if installments_count.zero?
    (((installments_count - remaining_installments).to_f / installments_count) * 100).to_f
  end
end
