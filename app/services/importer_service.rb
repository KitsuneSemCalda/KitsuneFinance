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
    transactions = []
    CSV.foreach(file.path, headers: true) do |row|
      begin
        transactions << create_transaction(
          user: user,
          account: account,
          date: Date.parse(row["date"]),
          description: row["description"],
          amount: (row["amount"].to_f * 100).to_i,
          type: row["type"] || "expense"
        )
      rescue Date::Error, ArgumentError => e
        Rails.logger.warn "ImporterService skipped CSV row: #{e.message}"
      end
    end
    transactions.compact
  end

  def self.import_ofx(file, user, account)
    transactions = []
    OFX(file.path) do |ofx|
      # Bank Inference
      if account.bank_code.blank? && ofx.account.bank_id.present?
        bank_id = ofx.account.bank_id
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
          amount: (tx.amount.to_f.abs * 100).to_i,
          type: tx.amount > 0 ? "income" : "expense"
        )
      end
    end
    transactions.compact
  end

  def self.create_transaction(user:, account:, date:, description:, amount:, type:)
    return nil if user.transactions.where(
      account: account,
      date: date,
      amount: amount,
      description: description
    ).exists?

    category = auto_categorize(description, user)

    user.transactions.create(
      account: account,
      date: date,
      description: description,
      amount: amount,
      transaction_type: type,
      category: category
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.warn "ImporterService skipped row: #{e.message}"
    nil
  end

  def self.auto_categorize(description, user)
    # 1. Try user-defined custom rules (Highest priority)
    custom_category = CategorizationRule.match(description, user)
    return custom_category if custom_category

    # 2. Check for Investment Income (Dividends/JCP)
    desc_up = description.upcase
    if desc_up.include?("DIVIDENDO") || desc_up.include?("PROVENTO") || desc_up.include?("JCP") || desc_up.include?("RENDIMENTO")
      ticker_match = user.investments.pluck(:ticker).find { |t| desc_up.include?(t.upcase) }
      if ticker_match
        return user.categories.find_or_create_by!(name: "Investimentos", transaction_type: "income")
      end
    end

    # 3. Try to extract CNPJ from description
    cnpj_match = description.match(/\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}/)
    if cnpj_match
      company_data = BrasilApiService.fetch_company_data(cnpj_match[0])
      if company_data
        category_name = BrasilApiService.map_cnae_to_category(company_data["cnae_fiscal_descricao"])
        return user.categories.find_or_create_by(name: category_name) if category_name
      end
    end

    # 4. Fallback to keyword matching
    match = user.categorization_suggestions.includes(:category).find { |s| description.upcase.include?(s.keyword.upcase) }
    return match.category if match

    nil
  end
end
