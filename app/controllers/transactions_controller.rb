class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Transações"
    @transactions = current_user.transactions.includes(:category, :account).order(date: :desc, created_at: :desc)

    # Search & Filters
    if params[:search].present?
      @transactions = @transactions.where("LOWER(description) LIKE ?", "%#{params[:search].downcase}%")
    end
    if params[:transaction_type].present?
      @transactions = @transactions.where(transaction_type: params[:transaction_type])
    end
    if params[:category_id].present?
      @transactions = @transactions.where(category_id: params[:category_id])
    end
    if params[:account_id].present?
      @transactions = @transactions.where(account_id: params[:account_id])
    end
    if params[:date_from].present? && params[:date_to].present?
      @transactions = @transactions.where(date: params[:date_from]..params[:date_to])
    end

    @categories = current_user.categories.order(:name)
    @accounts = current_user.accounts.order(:name)

    respond_to do |format|
      format.html
      format.json { render json: @transactions.limit(50).map { |tx| tx.attributes.slice("id", "description", "amount", "transaction_type", "date", "created_at").merge(category_name: tx.category&.name, account_name: tx.account&.name) } }
      format.any(:csv) { send_data generate_csv(@transactions), filename: "transacoes-#{Date.today}.csv" }
      format.any(:xlsx) { response.headers["Content-Disposition"] = "attachment; filename=\"transacoes-#{Date.today}.xlsx\"" }
    end
  end

  def new
    @page_title = "Nova Transação"
    @transaction = current_user.transactions.new(date: Date.today)

    if params[:duplicate_from].present?
      original = current_user.transactions.find(params[:duplicate_from])
      @transaction.assign_attributes(
        description: original.description,
        amount: original.amount,
        transaction_type: original.transaction_type,
        category_id: original.category_id,
        account_id: original.account_id,
        notes: original.notes
      )
    end
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    @transaction.total_installments = nil if params[:installment].blank?

    if @transaction.save
      create_installments if params[:installment].present? && @transaction.total_installments.to_i > 1

      respond_to do |format|
        format.html { redirect_to dashboard_transactions_path, notice: "Transação registrada com sucesso." }
        format.json { render json: { success: true, transaction: @transaction }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: @transaction.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @page_title = "Editar Transação"
  end

  def update
    old_category_id = @transaction.category_id
    if @transaction.update(transaction_params)
      # Intelligent Re-categorization Rule
      if @transaction.category_id.present? && @transaction.category_id != old_category_id
        create_smart_categorization_rule(@transaction)
      end
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

    if file.nil?
      redirect_to import_dashboard_transactions_path, alert: "Selecione um arquivo para importar."
      return
    end

    format = params[:format]&.to_sym || (file.original_filename.downcase.end_with?(".ofx") ? :ofx : :csv)

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

  def create_smart_categorization_rule(transaction)
    # Don't create rules for very short descriptions or numeric ones
    return if transaction.description.length < 4 || transaction.description.match?(/\A\d+\z/)
    
    # Simple heuristic: use the first 2 words of the description as a keyword
    keyword = transaction.description.split(" ").take(2).join(" ").upcase
    
    return if CategorizationRule.exists?(user: current_user, keyword: keyword)

    CategorizationRule.create(
      user: current_user,
      category_id: transaction.category_id,
      keyword: keyword
    )
    
    NotificationService.notify(
      current_user,
      "Inteligência de Categorização",
      "Aprendi que '#{keyword}' pertence a #{transaction.category.name}. Transações futuras serão categorizadas automaticamente.",
      type: "info"
    )
  end

  def create_installments
    installment_count = @transaction.total_installments
    installment_amount = (@transaction.amount.to_f / installment_count).to_i
    base_date = @transaction.date

    (2..installment_count).each do |i|
      current_user.transactions.create!(
        account_id: @transaction.account_id,
        description: "#{@transaction.description} (#{i}/#{installment_count})",
        amount: installment_amount,
        transaction_type: @transaction.transaction_type,
        category_id: @transaction.category_id,
        date: base_date + (i - 1).month,
        notes: @transaction.notes,
        goal_id: @transaction.goal_id,
        installment_number: i,
        total_installments: installment_count,
        parent_transaction_id: @transaction.id
      )
    end
  end

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
    params.require(:transaction).permit(:account_id, :destination_account_id, :category_id, :description, :amount, :transaction_type, :date, :notes, :receipt, :total_installments)
  end
end
