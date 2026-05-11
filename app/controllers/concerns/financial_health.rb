module FinancialHealth
  extend ActiveSupport::Concern

  private

  def compute_health_metrics(user)
    salary = user.monthly_salary || 0
    salary_present = salary > 0
    monthly_income = user.transactions.income.current_month.sum(:amount)
    monthly_expense = user.transactions.expense.current_month.sum(:amount)
    monthly_debts = user.debts.sum(:monthly_payment)
    monthly_savings = monthly_income - monthly_expense - monthly_debts
    accounts_balance = user.accounts.sum(:balance)
    portfolio_value = user.investments.sum { |i| i.current_value }
    net_worth = accounts_balance + portfolio_value

    dti = salary_present ? (monthly_debts.to_f / salary) * 100 : nil
    expense_ratio = salary_present ? (monthly_expense.to_f / salary) * 100 : nil
    savings_rate = salary_present ? ((monthly_savings.to_f / salary) * 100).clamp(-999, 999) : nil
    net_worth_to_annual = salary_present ? net_worth.to_f / (salary * 12) : nil

    score = 0
    score += dti && dti <= 15 ? 25 : dti && dti <= 30 ? 20 : dti && dti <= 40 ? 15 : 0
    score += expense_ratio && expense_ratio <= 25 ? 25 : expense_ratio && expense_ratio <= 50 ? 20 : expense_ratio && expense_ratio <= 75 ? 15 : 0
    score += savings_rate && savings_rate >= 20 ? 25 : savings_rate && savings_rate >= 10 ? 20 : savings_rate && savings_rate >= 0 ? 15 : 0
    score += net_worth >= 0 ? 25 : 0
    score = score.clamp(0, 100)

    {
      salary: salary,
      salary_present: salary_present,
      monthly_income: monthly_income,
      monthly_expense: monthly_expense,
      monthly_debts: monthly_debts,
      monthly_savings: monthly_savings,
      net_worth: net_worth,
      dti: dti,
      expense_ratio: expense_ratio,
      savings_rate: savings_rate,
      net_worth_to_annual: net_worth_to_annual,
      health_score: score
    }
  end
end
