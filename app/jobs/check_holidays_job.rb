class CheckHolidaysJob < ApplicationJob
  queue_as :default

  def perform
    holidays = BrasilApiService.fetch_holidays
    today = Date.today
    
    # Check for holidays today or tomorrow
    holidays.each do |holiday|
      holiday_date = Date.parse(holiday["date"])
      
      if holiday_date == today
        notify_all_users("Feriado Hoje: #{holiday['name']}", "Hoje é feriado nacional. Fique atento ao funcionamento bancário e vencimento de contas.")
      elsif holiday_date == today + 1.day
        notify_all_users("Feriado Amanhã: #{holiday['name']}", "Lembrete: Amanhã é feriado. Antecipe seus pagamentos se necessário.")
      end
    end
  end

  private

  def notify_all_users(title, message)
    User.find_each do |user|
      NotificationService.notify(user, title, message, type: "info")
    end
  end
end
