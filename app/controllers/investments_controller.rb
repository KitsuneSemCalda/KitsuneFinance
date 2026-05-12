class InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_investment, only: %i[show edit update destroy refresh_price]
  layout "dashboard"

  def index
    @page_title = "Investimentos"
    @investments = current_user.investments.includes(:trades)
    @total_value = @investments.sum { |i| i.current_value }
  end

  def cards
    @page_title = "Ativos em Carteira"
    @investments = current_user.investments.includes(:trades)
    @total_value = @investments.sum { |i| i.current_value }
  end

  def show
    @trades = @investment.trades.ordered
  end

  def new
    @page_title = "Novo Investimento"
    @investment = current_user.investments.new
  end

  def create
    convert_price_params
    @investment = current_user.investments.new(investment_params)
    if @investment.save
      redirect_to dashboard_investments_path, notice: "Investimento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    convert_price_params
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
    end
    redirect_to dashboard_investments_path, notice: "Atualização de preços agendada para todos os ativos."
  end

  private

  def investment_json(inv)
    {
      id: inv.id,
      quantity: inv.quantity,
      avg_price: inv.avg_price,
      current_price: inv.current_price,
      current_value: inv.current_value,
      total_cost: inv.total_cost,
      gain_loss: inv.gain_loss,
      gain_loss_pct: inv.gain_loss_pct
    }
  end

  def set_investment
    @investment = current_user.investments.find(params[:id])
  end

  def investment_params
    params.require(:investment).permit(:name, :ticker, :asset_type, :quantity, :currency, :purchased_at, :notes, :avg_price, :current_price, :price_feed_url)
  end

  def convert_price_params
    %i[avg_price current_price].each do |field|
      next if params[:investment][field].blank?
      params[:investment][field] = (params[:investment][field].to_f * 100).to_i
    end
  end
end
