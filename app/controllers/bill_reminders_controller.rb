class BillRemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill_reminder, only: %i[edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Contas a Pagar"
    @bill_reminders = current_user.bill_reminders.this_month.ordered.includes(:category)
    @overdue = current_user.bill_reminders.overdue.ordered.includes(:category)
    @upcoming = current_user.bill_reminders.upcoming.ordered.includes(:category)
    @total_paid = current_user.bill_reminders.this_month.where(paid: true).sum(:amount)
    @total_pending = current_user.bill_reminders.this_month.where(paid: false).sum(:amount)
  end

  def new
    @page_title = "Nova Conta"
    @bill_reminder = current_user.bill_reminders.new(due_date: Date.today)
  end

  def create
    @bill_reminder = current_user.bill_reminders.new(bill_reminder_params)
    if @bill_reminder.save
      redirect_to dashboard_bill_reminders_path, notice: "Conta registrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page_title = "Editar Conta"
  end

  def update
    if @bill_reminder.update(bill_reminder_params)
      respond_to do |format|
        format.html { redirect_to dashboard_bill_reminders_path, notice: "Conta atualizada com sucesso." }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: @bill_reminder.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @bill_reminder.destroy
    redirect_to dashboard_bill_reminders_path, notice: "Conta excluída."
  end

  private

  def set_bill_reminder
    @bill_reminder = current_user.bill_reminders.find(params[:id])
  end

  def bill_reminder_params
    params.require(:bill_reminder).permit(:name, :amount, :due_date, :recurrent, :recurrence_period, :paid, :category_id, :notes, :color)
  end
end
