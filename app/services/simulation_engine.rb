class SimulationEngine
  def initialize(user)
    @user = user
  end

  def forecast(scenario = {})
    base_salary = @user.monthly_salary || 0
    salary = base_salary * (1 + (scenario[:salary_adjustment] || 0))
    
    base_expenses = @user.transactions.expense.current_month.sum(:amount)
    expenses = base_expenses * (1 - (scenario[:expense_adjustment] || 0))
    
    monthly_debts = @user.debts.sum(:monthly_payment)
    balance = salary - (expenses + monthly_debts)
    
    # Debt payoff projection
    total_debt_remaining = @user.debts.sum { |d| d.total_remaining }
    debt_months_to_payoff = monthly_debts > 0 ? (total_debt_remaining.to_f / monthly_debts).ceil : nil
    
    # Savings projection (12 months)
    monthly_savings = [balance, 0].max
    projected_net_worth_12m = monthly_savings * 12
    
    # Goal funding projections
    goal_projections = @user.goals.active.map do |goal|
      remaining = goal.target_amount - goal.current_amount
      next if remaining <= 0
      months = monthly_savings > 0 ? (remaining.to_f / monthly_savings).ceil : nil
      {
        name: goal.name,
        icon: goal.icon,
        remaining: remaining,
        monthly_savings_needed: months ? (remaining.to_f / months).ceil : nil,
        estimated_months: months
      }
    end.compact
    
    {
      projected_salary: salary,
      projected_expenses: expenses,
      monthly_debts: monthly_debts,
      monthly_savings: monthly_savings,
      balance: balance,
      debt_payoff_months: debt_months_to_payoff,
      total_debt_remaining: total_debt_remaining,
      projected_net_worth_12m: projected_net_worth_12m,
      goal_projections: goal_projections
    }
  end
end
