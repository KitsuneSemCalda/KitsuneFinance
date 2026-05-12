class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :debts, dependent: :destroy
  has_many :balance_snapshots, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :trades, dependent: :destroy
  has_many :bill_reminders, dependent: :destroy
  has_many :categorization_rules, dependent: :destroy

  def annual_salary
    (monthly_salary || 0) * 12
  end

  # Behavioral Constants
  SUGGESTED_SAVINGS_PERCENTAGE = 0.10 # 10%

  def suggested_monthly_savings
    ((monthly_salary || 0) * SUGGESTED_SAVINGS_PERCENTAGE).to_i
  end

  def portfolio_metrics
    total_v = investments.sum { |i| i.current_value }
    total_c = investments.sum { |i| i.total_cost }
    change = total_v - total_c
    change_pct = total_c.positive? ? ((total_v.to_f / total_c) - 1) * 100 : 0

    {
      total_value: total_v,
      total_cost: total_c,
      change: change,
      change_pct: change_pct
    }
  end

  def health_color_class
    score = financial_health_metrics[:health_score]
    if score >= 70
      "emerald"
    elsif score >= 40
      "amber"
    else
      "red"
    end
  end

  def health_status_label
    score = financial_health_metrics[:health_score]
    if score >= 70
      "Saudável"
    elsif score >= 40
      "Atenção"
    else
      "Crítico"
    end
  end

  def financial_health_metrics
    salary = monthly_salary || 0
    salary_present = salary > 0
    
    # Use current month's transactions
    m_income = transactions.income.current_month.sum(:amount)
    m_expense = transactions.expense.current_month.sum(:amount)
    m_debts = debts.sum(:monthly_payment)
    m_savings = m_income - m_expense - m_debts
    
    acc_balance = accounts.sum(:balance)
    port_value = investments.sum { |i| i.current_value }
    net_w = acc_balance + port_value

    dti = salary_present ? (m_debts.to_f / salary) * 100 : nil
    exp_ratio = salary_present ? (m_expense.to_f / salary) * 100 : nil
    sav_rate = salary_present ? ((m_savings.to_f / salary) * 100).clamp(-999, 999) : nil
    nw_to_annual = salary_present ? net_w.to_f / (salary * 12) : nil

    # Consistently calculate the score
    score = 0
    score += dti && dti <= 15 ? 25 : (dti && dti <= 30 ? 20 : (dti && dti <= 40 ? 15 : 0))
    score += exp_ratio && exp_ratio <= 25 ? 25 : (exp_ratio && exp_ratio <= 50 ? 20 : (exp_ratio && exp_ratio <= 75 ? 15 : 0))
    score += sav_rate && sav_rate >= 20 ? 25 : (sav_rate && sav_rate >= 10 ? 20 : (sav_rate && sav_rate >= 0 ? 15 : 0))
    score += net_w >= 0 ? 25 : 0
    score = score.clamp(0, 100)

    {
      salary: salary,
      salary_present: salary_present,
      monthly_income: m_income,
      monthly_expense: m_expense,
      monthly_debts: m_debts,
      monthly_savings: m_savings,
      net_worth: net_w,
      dti: dti,
      expense_ratio: exp_ratio,
      savings_rate: sav_rate,
      net_worth_to_annual: nw_to_annual,
      health_score: score
    }
  end

  def salary_label
    return "—" unless monthly_salary&.positive?
    ActionController::Base.helpers.number_to_currency(
      monthly_salary / 100.0, unit: "R$ ", separator: ",", delimiter: "."
    )
  end
end
