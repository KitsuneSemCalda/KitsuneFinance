class DashboardDataService
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  def initialize(user)
    @user = user
  end

  def insights
    InsightService.generate(@user)
  end

  def accounts
    @user.accounts
  end

  def financial_health
    @user.financial_health_metrics
  end

  def recent_transactions_more
    @user.transactions.recent.includes(:category).limit(15)
  end

  def yearly_summary
    build_monthly_summary(12)
  end

  def portfolio_metrics
    pm = @user.portfolio_metrics
    {
      total: pm[:total_value],
      change: pm[:change],
      change_pct: pm[:change_pct]
    }
  end

  def recent_transactions
    @user.transactions.recent.includes(:category).map do |tx|
      {
        icon: tx.category&.icon || "💰",
        description: tx.description,
        category: tx.category&.name || "Sem categoria",
        date: tx.date.strftime("%d %b"),
        amount: tx.amount,
        type: tx.transaction_type.to_sym
      }
    end
  end

  def goals
    @user.goals.limit(3).map do |goal|
      remaining = goal.target_amount - goal.current_amount
      monthly_savings_est = @user.suggested_monthly_savings
      estimated_months = remaining > 0 && monthly_savings_est > 0 ? (remaining.to_f / monthly_savings_est).ceil : nil
      {
        name: goal.name,
        icon: goal.icon,
        current: goal.current_amount,
        target: goal.target_amount,
        color: goal.color,
        pct: goal.progress_pct,
        estimated_months: estimated_months
      }
    end
  end

  def allocation
    alloc = @user.investments.group(:asset_type).sum("quantity * current_price")
    {
      by_type: alloc,
      total: alloc.values.sum,
      json: alloc.map { |k, v| { label: I18n.t("activerecord.enums.investment.asset_type.#{k}", default: k.to_s.humanize), value: v } }.to_json
    }
  end

  def cash_flow_30
    build_cash_flow(29)
  end

  def cash_flow_60
    build_cash_flow(59)
  end

  def available_balance
    @user.accounts.where(account_type: %w[checking savings]).sum(:balance)
  end

  def investment_count
    @user.investments.count
  end

  def bills_pending
    @user.bill_reminders.this_month.where(paid: false).sum(:amount)
  end

  def bills_overdue_count
    @user.bill_reminders.overdue.count
  end

  def recent_trades
    Trade.where(user: @user).order(date: :desc).includes(:investment).limit(5)
  end

  def budgets_with_progress
    @user.budgets.where(month: Date.today.month, year: Date.today.year).includes(:category).map do |b|
      {
        category: b.category.name,
        limit: b.limit_amount,
        spent: b.spent_amount,
        pct: b.progress_pct,
        over: b.over_budget?
      }
    end
  end

  def debt_timeline
    total_remaining = @user.debts.sum("remaining_installments * monthly_payment")
    total_paid = @user.debts.sum("total_amount - remaining_installments * monthly_payment")
    total_original = @user.debts.sum(:total_amount)
    progress_pct = total_original > 0 ? (total_paid.to_f / total_original) * 100 : 0
    monthly_debts = financial_health[:monthly_debts]
    estimated_months = monthly_debts > 0 ? (total_remaining.to_f / monthly_debts).ceil : nil

    {
      total_remaining: total_remaining,
      progress_pct: progress_pct,
      estimated_months: estimated_months,
      next_payment: @user.debts.minimum(:monthly_payment) || 0
    }
  end

  def health_investments
    @user.investments
  end

  def health_allocation
    @user.investments.group(:asset_type).count
  end

  def total_gain_loss
    health_investments.sum("quantity * (current_price - avg_price)")
  end

  def health_goals
    @user.goals
  end

  def debt_progress
    total = @user.debts.sum(:total_amount)
    remaining = @user.debts.sum("remaining_installments * monthly_payment")
    total > 0 ? ((total - remaining).to_f / total) * 100 : 0
  end

  def recommendations
    m = financial_health
    investments = health_investments
    goals = health_goals
    recs = []

    if m[:dti] && m[:dti] > 40
      recs << { type: :danger, icon: "🚨", title: "Endividamento Crítico", desc: "Seu comprometimento de renda com dívidas é de #{number_to_percentage(m[:dti], precision: 1)}. Ideal é manter abaixo de 30%. Considere renegociar prazos ou buscar fontes de renda extra." }
    elsif m[:dti] && m[:dti] > 30
      recs << { type: :warning, icon: "⚠️", title: "Endividamento Elevado", desc: "Seu DTI de #{number_to_percentage(m[:dti], precision: 1)} está acima do recomendado (30%). Evite novas dívidas e foque em quitar as existentes." }
    elsif m[:dti] && m[:dti] <= 15
      recs << { type: :success, icon: "✅", title: "Endividamento Controlado", desc: "Seu DTI de #{number_to_percentage(m[:dti], precision: 1)} está excelente. Você tem boa margem para poupar e investir." }
    end

    if m[:expense_ratio] && m[:expense_ratio] > 75
      recs << { type: :danger, icon: "🔥", title: "Gastos Muito Altos", desc: "Você gasta #{number_to_percentage(m[:expense_ratio], precision: 1)} do seu salário. Tente reduzir para no máximo 50% para ter folga financeira." }
    elsif m[:expense_ratio] && m[:expense_ratio] > 50
      recs << { type: :warning, icon: "📊", title: "Gastos Acima do Ideal", desc: "Seus gastos consomem #{number_to_percentage(m[:expense_ratio], precision: 1)} do salário. A recomendação é manter abaixo de 50%." }
    end

    if m[:savings_rate] && m[:savings_rate] >= 20
      recs << { type: :success, icon: "🏆", title: "Excelente Poupança", desc: "Você poupa #{number_to_percentage(m[:savings_rate], precision: 1)} do salário. Continue assim! Já pensou em direcionar para investimentos de longo prazo?" }
    elsif m[:savings_rate] && m[:savings_rate] >= 10
      recs << { type: :success, icon: "👍", title: "Boa Taxa de Poupança", desc: "Poupando #{number_to_percentage(m[:savings_rate], precision: 1)} do salário, você está no caminho certo. Tente chegar a 20%." }
    elsif m[:savings_rate] && m[:savings_rate] < 0
      recs << { type: :danger, icon: "📉", title: "Orçamento Negativo", desc: "Suas despesas superam sua receita em #{number_to_currency(m[:monthly_savings].abs / 100.0)}. Reveja seus gastos urgentemente." }
    end

    if m[:net_worth] > 0 && m[:net_worth_to_annual] && m[:net_worth_to_annual] < 1
      recs << { type: :info, icon: "💡", title: "Construindo Patrimônio", desc: "Seu patrimônio é de #{number_to_percentage(m[:net_worth_to_annual] * 100, precision: 0)} da sua renda anual. Meta: acumular 1 ano de despesas como reserva de emergência." }
    elsif m[:net_worth] > 0 && m[:net_worth_to_annual] && m[:net_worth_to_annual] >= 3
      recs << { type: :success, icon: "🌟", title: "Patrimônio Sólido", desc: "Seu patrimônio equivale a #{number_to_percentage(m[:net_worth_to_annual] * 100, precision: 0)} da renda anual. Excelente solidez financeira!" }
    end

    if investments.none?
      recs << { type: :info, icon: "📈", title: "Comece a Investir", desc: "Você ainda não tem investimentos. Considere alocar parte da sua poupança em ativos como Tesouro Direto, CDBs ou fundos imobiliários." }
    end

    if goals.active.any? && goals.active.none? { |g| g.progress_pct > 50 }
      recs << { type: :info, icon: "🎯", title: "Metas em Andamento", desc: "Você tem #{goals.active.count} meta(s) ativa(s). Foque em concluir a mais próxima para ganhar impulso." }
    end

    recs
  end

  def reports_summary
    total_income = @user.transactions.income.sum(:amount)
    total_expense = @user.transactions.expense.sum(:amount)
    { total_income: total_income, total_expense: total_expense, balance: total_income - total_expense }
  end

  def monthly_report_data
    build_monthly_summary(6, format: "%b/%y")
  end

  def reports_indicators
    salary = @user.monthly_salary || 0
    salary_present = salary > 0
    {
      salary: salary,
      salary_present: salary_present,
      expense_ratio: salary_present ? (@user.transactions.expense.sum(:amount).to_f / salary) * 100 : nil,
      dti: salary_present ? (@user.debts.sum(:monthly_payment).to_f / salary) * 100 : nil
    }
  end

  def category_distribution
    @user.transactions.expense
         .joins(:category)
         .group("categories.name")
         .sum(:amount)
         .sort_by { |_, amount| -amount }
         .first(5)
  end

  private

  def build_monthly_summary(months, format: "%b")
    cutoff = months.months.ago.beginning_of_month
    income = @user.transactions.income.where("date >= ?", cutoff)
                  .group("strftime('%Y-%m', date)").sum(:amount)
    expense = @user.transactions.expense.where("date >= ?", cutoff)
                   .group("strftime('%Y-%m', date)").sum(:amount)

    (0..months - 1).reverse_each.map do |i|
      date = i.months.ago.beginning_of_month
      key = date.strftime("%Y-%m")
      {
        month: I18n.l(date, format: format),
        income: income[key] || 0,
        expense: expense[key] || 0
      }
    end
  end

  def build_cash_flow(days_ago)
    start_date = days_ago.days.ago.to_date
    labels = (start_date..Date.today).map { |d| d.strftime("%d/%m") }

    income_data = @user.transactions.income.where(date: start_date..Date.today).group(:date).sum(:amount)
    expense_data = @user.transactions.expense.where(date: start_date..Date.today).group(:date).sum(:amount)

    income_series = (start_date..Date.today).map { |d| income_data[d] || 0 }
    expense_series = (start_date..Date.today).map { |d| expense_data[d] || 0 }

    { labels: labels, income: income_series, expense: expense_series }
  end
end
