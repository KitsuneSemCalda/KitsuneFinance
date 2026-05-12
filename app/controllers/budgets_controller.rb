class BudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget, only: %i[show edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Orçamento"
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year
    @budgets = current_user.budgets.where(month: @month, year: @year)
  end

  def show
    @page_title = "#{@budget.category.name} — #{t("date.month_names")[@budget.month]} #{@budget.year}"
    @transactions = current_user.transactions
      .expense
      .where(category_id: @budget.category_id)
      .where(date: Date.new(@budget.year, @budget.month, 1)..Date.new(@budget.year, @budget.month, -1))
      .order(date: :desc)
      .limit(20)
  end

  def new
    @page_title = "Novo Orçamento"
    @budget = current_user.budgets.new(month: Date.today.month, year: Date.today.year)
  end

  def create
    params[:budget][:limit_amount] = (params[:budget][:limit_amount].to_f * 100).to_i if params[:budget][:limit_amount].present?
    @budget = current_user.budgets.new(budget_params)
    if @budget.save
      redirect_to dashboard_budgets_path(month: @budget.month, year: @budget.year), notice: "Orçamento definido com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page_title = "Editar Orçamento"
  end

  def update
    params[:budget][:limit_amount] = (params[:budget][:limit_amount].to_f * 100).to_i if params[:budget][:limit_amount].present?
    if @budget.update(budget_params)
      redirect_to dashboard_budgets_path(month: @budget.month, year: @budget.year), notice: "Orçamento atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    month, year = @budget.month, @budget.year
    @budget.destroy
    redirect_to dashboard_budgets_path(month: month, year: year), notice: "Orçamento excluído."
  end

  private

  def set_budget
    @budget = current_user.budgets.find(params[:id])
  end

  def budget_params
    params.require(:budget).permit(:category_id, :month, :year, :limit_amount)
  end
end
