require "test_helper"

class NotificationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "notify creates a notification" do
    assert_difference("Notification.count") do
      NotificationService.notify(@user, "Teste", "Mensagem de teste", type: "info")
    end
  end

  test "notify returns the created notification" do
    notification = NotificationService.notify(@user, "Teste", "Mensagem", type: "info")
    assert_kind_of Notification, notification
    assert_equal "Teste", notification.title
    assert_equal "Mensagem", notification.message
    assert_equal "info", notification.notification_type
  end

  test "notify with link stores the link" do
    notification = NotificationService.notify(@user, "Link", "Com link", type: "info", link: "/dashboard")
    assert_equal "/dashboard", notification.link
  end
end