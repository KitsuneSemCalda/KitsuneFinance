class IndicatorsService
  BCB_BASE_URL = "https://api.bcb.gov.br/dados/serie"

  # Series IDs:
  # 432: Selic (meta)
  # 12: CDI (diário)
  # 433: IPCA (mensal)
  SERIES = {
    selic: 432,
    cdi: 12,
    ipca: 433
  }

  def self.fetch_latest(indicator)
    series_id = SERIES[indicator.to_sym]
    return nil unless series_id

    response = Faraday.get("#{BCB_BASE_URL}/bcdata.sgs.#{series_id}/dados/ultimos/1?formato=json")
    return nil unless response.success?

    data = JSON.parse(response.body)
    data.first["valor"]&.to_f
  rescue StandardError => e
    Rails.logger.error "IndicatorsService Error: #{e.message}"
    nil
  end
end
