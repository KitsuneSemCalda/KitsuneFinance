class InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_investment, only: %i[show edit update destroy refresh_price]
  layout "dashboard"

  def index
    @page_title = "Investimentos"
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
      if @investment.quantity > 0 && @investment.trades.none?
        buy_price = @investment.avg_price > 0 ? @investment.avg_price : @investment.current_price
        if buy_price > 0
          @investment.trades.create!(
            user: current_user,
            trade_type: :buy,
            quantity: @investment.quantity,
            price: buy_price,
            date: @investment.purchased_at.presence || Date.today,
            notes: "Compra inicial"
          )
        end
      end
      redirect_to dashboard_investments_path, notice: "Investimento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    convert_price_params
    @investment.assign_attributes(investment_params)
    if @investment.save
      if @investment.quantity > 0 && @investment.trades.none?
        buy_price = @investment.avg_price > 0 ? @investment.avg_price : @investment.current_price
        if buy_price > 0
          @investment.trades.create!(
            user: current_user,
            trade_type: :buy,
            quantity: @investment.quantity,
            price: buy_price,
            date: @investment.purchased_at.presence || Date.today,
            notes: "Compra inicial"
          )
        end
      end
      redirect_to dashboard_investments_path, notice: "Investimento atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
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

  private

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
