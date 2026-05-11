class BrasilApiService
  BASE_URL = "https://brasilapi.com.br/api/cnpj/v1"

  def self.fetch_company_data(cnpj)
    # Remove non-digits
    clean_cnpj = cnpj.to_s.gsub(/\D/, "")
    return nil if clean_cnpj.length != 14

    response = Faraday.get("#{BASE_URL}/#{clean_cnpj}")
    return nil unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "BrasilApiService Error: #{e.message}"
    nil
  end

  def self.map_cnae_to_category(cnae_description)
    return nil if cnae_description.blank?

    desc = cnae_description.downcase
    
    case
    when desc.include?("restaurantes") || desc.include?("alimentação") || desc.include?("lanchonetes")
      "Alimentação"
    when desc.include?("supermercados") || desc.include?("minimercados") || desc.include?("mercearia")
      "Alimentação"
    when desc.include?("farmácias") || desc.include?("medicamentos") || desc.include?("saúde")
      "Saúde"
    when desc.include?("transporte") || desc.include?("táxi") || desc.include?("locação de veículos")
      "Transporte"
    when desc.include?("vestuário") || desc.include?("calçados") || desc.include?("artigos do vestuário")
      "Compras"
    when desc.include?("eletrônicos") || desc.include?("informática") || desc.include?("eletrodomésticos")
      "Compras"
    when desc.include?("educação") || desc.include?("ensino") || desc.include?("escola")
      "Educação"
    when desc.include?("lazer") || desc.include?("cultura") || desc.include?("cinemas") || desc.include?("parques")
      "Lazer"
    when desc.include?("energia elétrica") || desc.include?("água") || desc.include?("telefonia")
      "Contas Fixas"
    else
      nil
    end
  end

  def self.fetch_banks
    response = Faraday.get("https://brasilapi.com.br/api/banks/v1")
    return [] unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "BrasilApiService (Banks) Error: #{e.message}"
    []
  end

  def self.fetch_holidays(year = Date.today.year)
    response = Faraday.get("https://brasilapi.com.br/api/feriados/v1/#{year}")
    return [] unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "BrasilApiService (Holidays) Error: #{e.message}"
    []
  end
end
