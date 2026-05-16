require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @notification = notifications(:one)
    sign_in @user
  end

  test "index lists unread notifications sorted recent first" do
    newer = Notification.create!(user: @user, title: "Mais Recente", message: "Nova", notification_type: "info")
    get dashboard_notifications_url
    assert_select "h3", text: /Bem-vindo/
    assert_select "h3", text: /Orçamento/
    # Verifica ordenação (mais recente primeiro)
    assert response.body.index("Mais Recente") < response.body.index("Bem-vindo"),
           "Newer notification should appear first"
  end

  test "mark as read sets read_at" do
    patch dashboard_notification_url(@notification)
    assert_redirected_to dashboard_notifications_path
    assert_not_nil @notification.reload.read_at
  end

  test "mark all as read clears all unread" do
    Notification.create!(user: @user, title: "Extra", message: "Test", notification_type: "info")
    post mark_all_as_read_dashboard_notifications_url
    assert_redirected_to dashboard_notifications_path
    assert @user.notifications.unread.empty?
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_notifications_url
    assert_redirected_to new_user_session_path
  end
end