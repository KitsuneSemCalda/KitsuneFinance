class FinancialSimulationService
  def initialize(user)
    @user = user
  end

  def monthly_forecast
    salary = @user.monthly_salary || 0
    expenses = @user.transactions.expense.current_month.sum(:amount)
    monthly_debts = @user.debts.sum(:monthly_payment)
    
    total_outflow = expenses + monthly_debts
    balance = salary - total_outflow

    {
      salary: salary,
      expenses: expenses,
      debts: monthly_debts,
      total_outflow: total_outflow,
      balance: balance
    }
  end
end
