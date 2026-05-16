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
  has_many :categorization_suggestions, dependent: :destroy

  SUGGESTED_SAVINGS_PERCENTAGE = 0.10
  ANNUAL_MULTIPLIER = 12

  DTI_EXCELLENT = 15
  DTI_GOOD = 30
  DTI_FAIR = 40

  EXPENSE_EXCELLENT = 25
  EXPENSE_GOOD = 50
  EXPENSE_FAIR = 75

  SAVINGS_EXCELLENT = 20
  SAVINGS_GOOD = 10

  SCORE_DTI = 25
  SCORE_EXPENSE = 25
  SCORE_SAVINGS = 25
  SCORE_NET_WORTH = 25

  HEALTH_GREEN = 70
  HEALTH_YELLOW = 40

  def annual_salary
    (monthly_salary || 0) * ANNUAL_MULTIPLIER
  end

  def suggested_monthly_savings
    ((monthly_salary || 0) * SUGGESTED_SAVINGS_PERCENTAGE).to_i
  end

  def portfolio_metrics
    total_v = investments.sum("quantity * current_price")
    total_c = investments.sum("quantity * avg_price")
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
    if score >= HEALTH_GREEN
      "emerald"
    elsif score >= HEALTH_YELLOW
      "amber"
    else
      "red"
    end
  end

  def health_status_label
    score = financial_health_metrics[:health_score]
    if score >= HEALTH_GREEN
      "Saudável"
    elsif score >= HEALTH_YELLOW
      "Atenção"
    else
      "Crítico"
    end
  end

  def financial_health_metrics
    salary = monthly_salary || 0
    salary_present = salary > 0

    m_income = transactions.income.current_month.sum(:amount)
    m_expense = transactions.expense.current_month.sum(:amount)
    m_debts = debts.sum(:monthly_payment)
    m_savings = m_income - m_expense - m_debts

    acc_balance = accounts.sum(:balance)
    port_value = investments.sum("quantity * current_price")
    total_debts = debts.sum("remaining_installments * monthly_payment")
    net_w = acc_balance + port_value - total_debts

    dti = salary_present ? (m_debts.to_f / salary) * 100 : nil
    exp_ratio = salary_present ? (m_expense.to_f / salary) * 100 : nil
    sav_rate = salary_present ? ((m_savings.to_f / salary) * 100).clamp(-999, 999) : nil
    nw_to_annual = salary_present ? net_w.to_f / (salary * ANNUAL_MULTIPLIER) : nil

    score = dti_score(dti) +
            expense_score(exp_ratio) +
            savings_score(sav_rate) +
            net_worth_score(net_w)
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
    ActionController::Base.helpers.number_to_currency(monthly_salary / 100.0)
  end

  private

  def dti_score(dti)
    return 0 if dti.nil?
    return SCORE_DTI     if dti <= DTI_EXCELLENT
    return SCORE_DTI - 5 if dti <= DTI_GOOD
    return SCORE_DTI - 10 if dti <= DTI_FAIR
    0
  end

  def expense_score(exp_ratio)
    return 0 if exp_ratio.nil?
    return SCORE_EXPENSE      if exp_ratio <= EXPENSE_EXCELLENT
    return SCORE_EXPENSE - 5  if exp_ratio <= EXPENSE_GOOD
    return SCORE_EXPENSE - 10 if exp_ratio <= EXPENSE_FAIR
    0
  end

  def savings_score(sav_rate)
    return 0 if sav_rate.nil?
    return SCORE_SAVINGS     if sav_rate >= SAVINGS_EXCELLENT
    return SCORE_SAVINGS - 5 if sav_rate >= SAVINGS_GOOD
    return SCORE_SAVINGS - 10 if sav_rate >= 0
    0
  end

  def net_worth_score(net_w)
    net_w >= 0 ? SCORE_NET_WORTH : 0
  end
end
