class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
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
end
