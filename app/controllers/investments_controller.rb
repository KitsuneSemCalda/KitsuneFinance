class InvestmentsController < ApplicationController
  include InvestmentJson
  before_action :authenticate_user!
  before_action :set_investment, only: %i[show edit update destroy refresh_price]
  layout "dashboard"

  def index
    @page_title = "Investimentos"
    @investments = current_user.investments.includes(:trades)
    @total_value = current_user.investments.sum("quantity * current_price")
  end

  def cards
    @page_title = "Ativos em Carteira"
    @investments = current_user.investments.includes(:trades)
    @total_value = current_user.investments.sum("quantity * current_price")
  end

  def show
    @trades = @investment.trades.ordered
  end

  def edit
    @page_title = "Editar Investimento"
  end

  def new
    @page_title = "Novo Investimento"
    @investment = current_user.investments.new
  end

  def create
    convert_to_cents(:avg_price, :current_price)
    @investment = current_user.investments.new(investment_params)
    if @investment.save
      redirect_to dashboard_investments_path, notice: "Investimento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    convert_to_cents(:avg_price, :current_price)
    if @investment.update(investment_params)
      respond_to do |format|
        format.html { redirect_to dashboard_investments_path, notice: "Investimento atualizado com sucesso." }
        format.json { render json: { investment: investment_json(@investment) }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @investment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @investment.destroy
    redirect_to dashboard_investments_path, notice: "Investimento excluído com sucesso."
  end

  def refresh_price
    InvestmentPriceRefreshJob.perform_later(@investment.id)
    redirect_to dashboard_investments_path, notice: "Atualização de preço agendada para #{@investment.name}."
  end

  def refresh_all_prices
    current_user.investments.find_each do |inv|
      InvestmentPriceRefreshJob.perform_later(inv.id)
    rescue StandardError => e
      Rails.logger.error "Failed to enqueue price refresh for investment #{inv.id}: #{e.message}"
    end
    redirect_to dashboard_investments_path, notice: "Atualização de preços agendada para todos os ativos."
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:id])
  end

  def investment_params
    params.require(:investment).permit(:name, :ticker, :asset_type, :quantity, :currency, :purchased_at, :notes, :avg_price, :current_price, :price_feed_url)
  end
end
