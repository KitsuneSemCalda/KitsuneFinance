class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Transações"
    @transactions = current_user.transactions.order(date: :desc, created_at: :desc)

    respond_to do |format|
      format.html
      format.any(:csv) { send_data generate_csv(@transactions), filename: "transacoes-#{Date.today}.csv" }
      format.any(:xlsx) { response.headers["Content-Disposition"] = "attachment; filename=\"transacoes-#{Date.today}.xlsx\"" }
    end
  end

  def new
    @page_title = "Nova Transação"
    @transaction = current_user.transactions.new(date: Date.today)
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    if @transaction.save
      redirect_to dashboard_transactions_path, notice: "Transação registrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page_title = "Editar Transação"
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to dashboard_transactions_path, notice: "Transação atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to dashboard_transactions_path, notice: "Transação excluída com sucesso."
  end

  def import
    @page_title = "Importar Transações"
    @accounts = current_user.accounts
  end

  def do_import
    file = params[:file]
    account = current_user.accounts.find(params[:account_id])
    format = params[:format] || (file.original_filename.downcase.end_with?(".ofx") ? :ofx : :csv)

    begin
      imported_transactions = ImporterService.import(file, current_user, account, format: format)
      
      if imported_transactions.any?
        NotificationService.notify(
          current_user,
          "Importação Concluída",
          "#{imported_transactions.count} novas transações foram importadas com sucesso para #{account.name}.",
          type: "success",
          link: dashboard_transactions_path
        )
        redirect_to dashboard_transactions_path, notice: "#{imported_transactions.count} transações importadas com sucesso."
      else
        redirect_to import_dashboard_transactions_path, alert: "Nenhuma nova transação encontrada no arquivo."
      end
    rescue StandardError => e
      redirect_to import_dashboard_transactions_path, alert: "Erro na importação: #{e.message}"
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def generate_csv(transactions)
    CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << [ "Data", "Descrição", "Categoria", "Valor", "Tipo", "Notas" ]
      transactions.each do |tx|
        csv << [ tx.date, tx.description, tx.category&.name, tx.amount, tx.transaction_type, tx.notes ]
      end
    end
  end

  def transaction_params
    params.require(:transaction).permit(:account_id, :category_id, :description, :amount, :transaction_type, :date, :notes)
  end
end
