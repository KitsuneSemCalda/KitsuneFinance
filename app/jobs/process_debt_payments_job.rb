class ProcessDebtPaymentsJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      user.debts.where("remaining_installments > 0").find_each do |debt|
        DebtManagerService.process_monthly_payment(debt)
      end
    end
  end
end
