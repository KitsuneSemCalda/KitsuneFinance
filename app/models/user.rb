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
  has_many :categorization_rules, dependent: :destroy

  def annual_salary
    monthly_salary * 12 if monthly_salary&.positive?
  end

  def debt_to_income_ratio
    return nil unless monthly_salary&.positive?
    (debts.sum(:monthly_payment).to_f / monthly_salary) * 100
  end

  def savings_rate(monthly_income, monthly_expense, monthly_debts)
    return nil unless monthly_salary&.positive?
    savings = monthly_income - monthly_expense - monthly_debts
    (savings.to_f / monthly_salary) * 100
  end

  def salary_label
    return "—" unless monthly_salary&.positive?
    ActionController::Base.helpers.number_to_currency(
      monthly_salary / 100.0, unit: "R$ ", separator: ",", delimiter: "."
    )
  end
end
