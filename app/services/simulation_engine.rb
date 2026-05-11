class SimulationEngine
  def initialize(user)
    @user = user
  end

  def forecast(scenario = {})
    # Scenario: { salary_adjustment: 0.0, expense_adjustment: 0.0 }
    base_salary = @user.monthly_salary || 0
    salary = base_salary * (1 + (scenario[:salary_adjustment] || 0))
    
    base_expenses = @user.transactions.expense.current_month.sum(:amount)
    expenses = base_expenses * (1 - (scenario[:expense_adjustment] || 0))
    
    monthly_debts = @user.debts.sum(:monthly_payment)
    
    {
      projected_salary: salary,
      projected_expenses: expenses,
      monthly_debts: monthly_debts,
      balance: salary - (expenses + monthly_debts)
    }
  end
end
