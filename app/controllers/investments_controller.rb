class InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_investment, only: %i[edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Investimentos"
    @investments = current_user.investments
    @total_value = @investments.sum { |i| i.current_value }
  end

  def new
    @page_title = "Novo Investimento"
    @investment = current_user.investments.new
  end

  def create
    params[:investment][:avg_price] = (params[:investment][:avg_price].to_f * 100).to_i if params[:investment][:avg_price].present?
    params[:investment][:current_price] = (params[:investment][:current_price].to_f * 100).to_i if params[:investment][:current_price].present?
    
    @investment = current_user.investments.new(investment_params)
    if @investment.save
      redirect_to dashboard_investments_path, notice: "Investimento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    params[:investment][:avg_price] = (params[:investment][:avg_price].to_f * 100).to_i if params[:investment][:avg_price].present?
    params[:investment][:current_price] = (params[:investment][:current_price].to_f * 100).to_i if params[:investment][:current_price].present?

    if @investment.update(investment_params)
      redirect_to dashboard_investments_path, notice: "Investimento atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @investment.destroy
    redirect_to dashboard_investments_path, notice: "Investimento excluído com sucesso."
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:id])
  end

  def investment_params
    params.require(:investment).permit(:name, :ticker, :asset_type, :quantity, :avg_price, :current_price, :currency, :purchased_at, :notes)
  end
end
