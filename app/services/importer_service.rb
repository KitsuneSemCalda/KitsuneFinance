require "csv"
require "ofx"

class ImporterService
  def self.import(file, user, account, format: :csv)
    case format.to_sym
    when :csv
      import_csv(file, user, account)
    when :ofx
      import_ofx(file, user, account)
    else
      raise "Formato não suportado: #{format}"
    end
  end

  private

  def self.import_csv(file, user, account)
    # Simple CSV import assuming: date, description, amount, type
    # This is a baseline, in a real app we'd have a mapper
    transactions = []
    CSV.foreach(file.path, headers: true) do |row|
      transactions << create_transaction(
        user: user,
        account: account,
        date: Date.parse(row["date"]),
        description: row["description"],
        amount: row["amount"].to_f,
        type: row["type"] || "expense"
      )
    end
    transactions.compact
  end

  def self.import_ofx(file, user, account)
    transactions = []
    OFX(file.path) do |ofx|
      # Bank Inference
      if account.bank_code.blank? && ofx.header["BANKID"].present?
        bank_id = ofx.header["BANKID"]
        banks = BrasilApiService.fetch_banks
        bank = banks.find { |b| b["code"] == bank_id.to_i }
        
        if bank
          account.update(bank_code: bank["code"], bank_name: bank["name"])
          NotificationService.notify(user, "Banco Identificado", "Identificamos que a conta #{account.name} pertence ao #{bank['name']}.", type: "info")
        end
      end

      ofx.account.transactions.each do |tx|
        transactions << create_transaction(
          user: user,
          account: account,
          date: tx.posted_at,
          description: tx.memo || tx.name,
          amount: tx.amount.to_f.abs,
          type: tx.amount > 0 ? "income" : "expense"
        )
      end
    end
    transactions.compact
  end

  def self.create_transaction(user:, account:, date:, description:, amount:, type:)
    # Simple duplicate detection
    return nil if user.transactions.where(
      account: account,
      date: date,
      amount: amount,
      description: description
    ).exists?

    # Basic auto-categorization
    category = auto_categorize(description, user)

    user.transactions.create!(
      account: account,
      date: date,
      description: description,
      amount: amount,
      transaction_type: type,
      category: category
    )
  end

  def self.auto_categorize(description, user)
    # 1. Try user-defined custom rules (Highest priority)
    custom_category = CategorizationRule.match(description, user)
    return custom_category if custom_category

    # 2. Try to extract CNPJ from description
    cnpj_match = description.match(/\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}/)
    if cnpj_match
      company_data = BrasilApiService.fetch_company_data(cnpj_match[0])
      if company_data
        category_name = BrasilApiService.map_cnae_to_category(company_data["cnae_fiscal_descricao"])
        return user.categories.find_or_create_by(name: category_name) if category_name
      end
    end

    # 2. Fallback to keyword matching
    keywords = {
      "IFOOD" => "Alimentação",
      "RAPPID" => "Alimentação",
      "UBER" => "Transporte",
      "99APP" => "Transporte",
      "NETFLIX" => "Lazer",
      "SPOTIFY" => "Lazer",
      "AMAZON" => "Compras",
      "MERCADO LIVRE" => "Compras",
      "MAGALU" => "Compras",
      "MERCADO" => "Alimentação",
      "CARREFOUR" => "Alimentação",
      "PÃO DE AÇUCAR" => "Alimentação",
      "POSTO" => "Transporte",
      "SHELL" => "Transporte",
      "IPIRANGA" => "Transporte",
      "FARMACIA" => "Saúde",
      "DROGASIL" => "Saúde",
      "RAIA" => "Saúde",
      "CONDOMINIO" => "Moradia",
      "ALUGUEL" => "Moradia",
      "ENEL" => "Contas Fixas",
      "SABESP" => "Contas Fixas",
      "VIVO" => "Contas Fixas",
      "CLARO" => "Contas Fixas"
    }

    match = keywords.find { |k, v| description.upcase.include?(k) }
    return nil unless match

    user.categories.find_or_create_by(name: match[1])
  end
end
