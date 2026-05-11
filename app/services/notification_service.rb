class NotificationService
  def self.notify(user, title, message, type: "info", link: nil)
    # 1. Create local notification
    notification = user.notifications.create!(
      title: title,
      message: message,
      notification_type: type,
      link: link
    )

    # 2. Send to external service if configured (ntfy/gotify)
    send_external_notification(user, title, message)
    
    notification
  end

  private

  def self.send_external_notification(user, title, message)
    # Priority: User preference > Environment variable
    ntfy_url = user.ntfy_url.presence || ENV["NTFY_URL"]
    return unless ntfy_url

    begin
      Faraday.post(ntfy_url, message, { "Title" => title })
    rescue StandardError => e
      Rails.logger.error "NotificationService External Error: #{e.message}"
    end
  end
end
