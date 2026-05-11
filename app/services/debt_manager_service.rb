class DebtManagerService
  def self.process_monthly_payment(debt)
    return if debt.remaining_installments <= 0

    debt.decrement!(:remaining_installments)
    # Optional: Log the transaction if desired
  end
end
