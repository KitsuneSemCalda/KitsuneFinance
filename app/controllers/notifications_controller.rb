class NotificationsController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @page_title = "Notificações"
    @notifications = current_user.notifications.order(created_at: :desc)
    
    # Mark all as read when viewing the index
    @notifications.unread.update_all(read_at: Time.current)
  end

  def update
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    redirect_back fallback_location: dashboard_notifications_path
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: dashboard_notifications_path, notice: "Todas as notificações foram marcadas como lidas."
  end
end
