class RecurringTransactionsJob < ApplicationJob
  queue_as :default

  PERIOD_MAP = {
    "daily"   => ->(date) { date + 1.day },
    "weekly"  => ->(date) { date + 1.week },
    "monthly" => ->(date) { date + 1.month },
    "yearly"  => ->(date) { date + 1.year }
  }.freeze

  def perform
    Transaction.where(recurrent: true).find_each do |template|
      next unless PERIOD_MAP.key?(template.recurrence_period)

      next_date = PERIOD_MAP[template.recurrence_period].call(template.date)

      next if next_date > Date.today

      already_exists = Transaction.exists?(
        user_id: template.user_id,
        account_id: template.account_id,
        description: template.description,
        amount: template.amount,
        transaction_type: template.transaction_type,
        category_id: template.category_id,
        date: next_date
      )

      unless already_exists
        Transaction.create!(
          user_id: template.user_id,
          account_id: template.account_id,
          description: template.description,
          amount: template.amount,
          transaction_type: template.transaction_type,
          category_id: template.category_id,
          goal_id: template.goal_id,
          notes: template.notes,
          recurrent: true,
          recurrence_period: template.recurrence_period,
          date: next_date
        )
      end
    end
  end
end
