require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "index shows KPI cards" do
    get dashboard_url
    assert_select "h2", text: /Olá, One/
    assert_select "span", text: /Patrimônio/
  end

  test "index shows recent transactions" do
    get dashboard_url
    assert_select "p", text: /Supermercado/
  end

  test "reports shows summary cards" do
    get dashboard_reports_url
    assert_select "h2", text: "Relatórios Financeiros"
    assert_select "span", /Total Recebido/
    assert_select "span", /Total Gasto/
  end

  test "simulation returns projected values" do
    get dashboard_simulation_url, params: { salary_adj: 10, expense_adj: 5 }
    assert_select "p", /Salário Projetado/
  end

  test "simulation without params uses defaults" do
    get dashboard_simulation_url
    assert_response :success
    assert_select "p", /Salário Projetado/
  end

  test "health shows recommendations" do
    get dashboard_health_url
    assert_select "h2", text: "Saúde Financeira"
  end

  test "settings show tab buttons" do
    get dashboard_settings_url
    assert_select "a", /Perfil/
    assert_select "a", /Preferências/
    assert_select "a", /Integrações/
    assert_select "a", /Conta/
  end

  test "settings tab param switches active tab" do
    get dashboard_settings_url, params: { tab: "preferences" }
    assert_response :success
  end

  test "update settings saves monthly salary in cents" do
    patch dashboard_settings_url, params: { user: { monthly_salary: 5000 } }
    assert_redirected_to dashboard_settings_path(tab: "profile")
    @user.reload
    assert_equal 500000, @user.monthly_salary
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_url
    assert_redirected_to new_user_session_path
  end

  test "news displays articles" do
    get dashboard_news_url
    assert_response :success
    assert_select "h2", text: "Notícias Financeiras"
  end

  test "indicators displays economic data" do
    get dashboard_indicators_url
    assert_response :success
    assert_select "h2", text: "Indicadores Econômicos"
  end

  test "backup returns JSON file" do
    get dashboard_backup_url
    assert_response :success
    assert_equal "application/json", response.media_type
    data = JSON.parse(response.body)
    assert_includes data, "exported_at"
    assert_includes data, "user"
    assert_includes data, "accounts"
    assert_includes data, "transactions"
  end
end