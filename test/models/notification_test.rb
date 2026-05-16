require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    notification = Notification.new(user: @user, title: "Teste", message: "Mensagem", notification_type: "info")
    assert notification.valid?
  end

  test "unread scope" do
    assert_includes Notification.unread, notifications(:one)
    Notification.create!(user: @user, title: "Lida", message: "Já vi", notification_type: "info", read_at: Time.current)
    assert_not_includes Notification.unread.map(&:title), "Lida"
  end

  test "mark_as_read!" do
    notification = notifications(:one)
    assert_nil notification.read_at
    notification.mark_as_read!
    assert_not_nil notification.reload.read_at
  end
end