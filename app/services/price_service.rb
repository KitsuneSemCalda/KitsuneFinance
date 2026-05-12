require "open-uri"
require "rexml/document"
require "json"
require "csv"

class PriceService
  BRAPI_BASE_URL = "https://brapi.dev/api"
  COINGECKO_BASE_URL = "https://api.coingecko.com/api/v3"
  YAHOO_BASE_URL = "https://query1.finance.yahoo.com/v8/finance/chart"
  ALPHA_VANTAGE_BASE_URL = "https://www.alphavantage.co/query"

  FALLBACK_ORDER = %i[brapi yahoo alpha_vantage statusinvest fundamentus].freeze

  # ── Public API ──────────────────────────────────────────────────

  def self.infer_asset_type(ticker)
    return "other" if ticker.blank?
    ticker = ticker.upcase.strip

    case
    when ticker.match?(/\A[A-Z]{4}[3456]\z/)
      "stock_br"
    when ticker.match?(/\A[A-Z]{4}11\z/)
      # Can be FII or ETF/BDR, but FII is most common in this context
      "fii"
    when %w[BTC ETH SOL ADA DOT DOGE XRP LINK LTC].include?(ticker) || ticker.match?(/(BTC|ETH|USD)\z/)
      "crypto"
    when ticker.match?(/\A[A-Z]{2,4}\z/) && !ticker.match?(/\d/)
      "international" # US stocks usually 2-4 letters, no numbers
    when ticker.downcase.start_with?("tesouro")
      "treasury_br"
    else
      "other"
    end
  end

  def self.fetch_price(ticker, asset_type, brapi_token = nil, price_feed_url: nil)
    return nil if ticker.blank?

    # 1. Try custom feed URL first (user-configured source)
    if price_feed_url.present?
      price = fetch_from_custom_url(price_feed_url)
      return price if price
    end

    # 2. Try provider chain based on asset type
    price = case asset_type
            when "stock_br", "fii"
              fetch_br_price(ticker, brapi_token)
            when "international"
              fetch_international_price(ticker)
            when "crypto"
              fetch_crypto_price(ticker.downcase)
            when "fixed_income"
              fetch_fixed_income_price(ticker)
            else
              nil
            end

    return price if price

    # 3. Universal fallback: Alpha Vantage (if configured)
    fetch_alpha_vantage_price(ticker)
  end

  def self.fetch_from_custom_url(url)
    return nil if url.blank?

    response = Faraday.get(url) do |req|
      req.headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
      req.options.timeout = 10
    end
    return nil unless response.success?

    body = response.body
    content_type = response.headers["content-type"].to_s.downcase

    price = nil

    # JSON API
    if content_type.include?("json") || body.strip.start_with?("{", "[")
      price = extract_price_from_json(body)
    end

    # RSS / Atom feed
    if price.nil? && (content_type.include?("xml") || content_type.include?("rss") || content_type.include?("atom") || body.strip.start_with?("<?xml"))
      price = extract_price_from_xml(body)
    end

    # HTML
    if price.nil? && (content_type.include?("html") || body.include?("<html") || body.include?("<!doctype"))
      price = extract_price_from_html(body)
    end

    # CSV
    if price.nil? && (content_type.include?("csv") || body.include?(";" || ","))
      price = extract_price_from_csv(body)
    end

    # Regex fallback: look for "R$ 123,45" patterns anywhere
    price || extract_price_with_regex(body)
  rescue StandardError => e
    Rails.logger.error "PriceService (CustomURL) Error: #{e.message}"
    nil
  end

  # ── BR Stocks / FIIs (full fallback chain) ──────────────────────

  def self.fetch_br_price(ticker, token)
    # 1. brapi.dev (user token)
    if token.present?
      price = fetch_brapi_price(ticker, token)
      return price if price
    end

    # 2. brapi.dev (global env token)
    if ENV["BRAPI_TOKEN"].present?
      price = fetch_brapi_price(ticker, ENV["BRAPI_TOKEN"])
      return price if price
    end

    # 3. Yahoo Finance (.SA suffix)
    yahoo_ticker = "#{ticker}.SA"
    price = fetch_yahoo_price(yahoo_ticker)
    return price if price

    # 4. Alpha Vantage
    price = fetch_alpha_vantage_price(ticker)
    return price if price

    # 5. StatusInvest scraping
    category = "acoes"
    price = fetch_statusinvest_price(ticker, category)
    return price if price

    # 6. Fundamentus scraping
    fetch_fundamentus_price(ticker)
  end

  # ── Provider: brapi.dev ────────────────────────────────────────

  def self.fetch_brapi_price(ticker, token)
    return nil unless token

    response = Faraday.get("#{BRAPI_BASE_URL}/quote/#{ticker}?token=#{token}")
    return nil unless response.success?

    data = JSON.parse(response.body)
    data.dig("results", 0, "regularMarketPrice")
  rescue StandardError => e
    Rails.logger.error "PriceService (brapi) Error: #{e.message}"
    nil
  end

  # ── Provider: Yahoo Finance ─────────────────────────────────────

  def self.fetch_yahoo_price(ticker)
    response = Faraday.get("#{YAHOO_BASE_URL}/#{ticker}") do |req|
      req.headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    end
    return nil unless response.success?

    data = JSON.parse(response.body)
    data.dig("chart", "result", 0, "meta", "regularMarketPrice")
  rescue StandardError => e
    Rails.logger.error "PriceService (Yahoo) Error: #{e.message}"
    nil
  end

  def self.fetch_international_price(ticker)
    price = fetch_yahoo_price(ticker)
    return nil unless price

    rate = ExchangeRateService.fetch_rate("USD", "BRL")
    return nil unless rate

    price * rate
  end

  # ── Provider: CoinGecko ────────────────────────────────────────

  def self.fetch_crypto_price(coin_id)
    response = Faraday.get("#{COINGECKO_BASE_URL}/simple/price?ids=#{coin_id}&vs_currencies=brl")
    return nil unless response.success?

    data = JSON.parse(response.body)
    data.dig(coin_id, "brl")
  rescue StandardError => e
    Rails.logger.error "PriceService (CoinGecko) Error: #{e.message}"
    nil
  end

  # ── Provider: Alpha Vantage ─────────────────────────────────────

  def self.fetch_alpha_vantage_price(ticker)
    api_key = ENV["ALPHA_VANTAGE_KEY"]
    return nil if api_key.blank?

    response = Faraday.get(ALPHA_VANTAGE_BASE_URL, {
      function: "GLOBAL_QUOTE",
      symbol: ticker,
      apikey: api_key
    })
    return nil unless response.success?

    data = JSON.parse(response.body)
    price_str = data.dig("Global Quote", "05. price")
    price_str&.to_f
  rescue StandardError => e
    Rails.logger.error "PriceService (AlphaVantage) Error: #{e.message}"
    nil
  end

  # ── Provider: StatusInvest ──────────────────────────────────────

  def self.fetch_statusinvest_price(ticker, category)
    url = "https://statusinvest.com.br/#{category}/#{ticker.downcase}"

    response = Faraday.get(url) do |req|
      req.headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
      req.headers["Accept"] = "text/html,application/xhtml+xml"
      req.options.timeout = 10
    end
    return nil unless response.success?

    extract_price_from_html(response.body)
  rescue StandardError => e
    Rails.logger.error "PriceService (StatusInvest) Error: #{e.message}"
    nil
  end

  # ── Provider: Fundamentus ───────────────────────────────────────

  def self.fetch_fundamentus_price(ticker)
    url = "https://www.fundamentus.com.br/detalhes.php?papel=#{ticker.upcase}"

    response = Faraday.get(url) do |req|
      req.headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
      req.options.timeout = 10
    end
    return nil unless response.success?

    extract_price_from_html(response.body)
  rescue StandardError => e
    Rails.logger.error "PriceService (Fundamentus) Error: #{e.message}"
    nil
  end

  # ── Provider: Fixed Income ──────────────────────────────────────

  def self.fetch_fixed_income_price(ticker)
    # For fixed income, try Tesouro Direto if ticker matches
    if ticker.downcase.start_with?("tesouro")
      fetch_tesouro_direto_price(ticker)
    else
      nil
    end
  end

  def self.fetch_tesouro_direto_price(ticker)
    url = "https://www.tesourodireto.com.br/json/br/com/b3/tesourodireto/service/api/treasurybondsinfo.json"

    response = Faraday.get(url, {}, { "User-Agent" => "Mozilla/5.0" })
    return nil unless response.success?

    data = JSON.parse(response.body)
    bonds = data.dig("response", "TrsrBondList") || []

    bond = bonds.find { |b| b["nm"].downcase.include?(ticker.downcase.gsub("tesouro", "").strip) }
    return nil unless bond

    bond["vlUnitSell"]&.to_f
  rescue StandardError => e
    Rails.logger.error "PriceService (TesouroDireto) Error: #{e.message}"
    nil
  end

  # ── Extractors (from generic URLs) ──────────────────────────────

  def self.extract_price_from_json(body)
    data = JSON.parse(body)

    # Try common JSON API patterns
    extract = lambda do |obj, *keys|
      keys.each do |key|
        case key
        when String, Symbol
          next unless obj.is_a?(Hash)
          obj = obj[key]
        when Integer
          next unless obj.is_a?(Array)
          obj = obj[key]
        end
      end
      obj.is_a?(Numeric) ? obj.to_f : (obj.to_s.to_f if obj.to_s.match?(/\A\d+\.?\d*\z/))
    end

    patterns = [
      -> { data.dig("price") },
      -> { data.dig("regularMarketPrice") },
      -> { data.dig("results", 0, "regularMarketPrice") },
      -> { data.dig("chart", "result", 0, "meta", "regularMarketPrice") },
      -> { data.dig("Global Quote", "05. price") },
      -> { data.dig("current_price") },
      -> { data.dig("data", "price") },
      -> { data.dig("value") }
    ]

    patterns.each do |pattern|
      val = pattern.call
      return val.to_f if val && val.to_s.match?(/\A-?\d+\.?\d*\z/)
    end

    nil
  rescue JSON::ParserError
    nil
  end

  def self.extract_price_from_xml(body)
    doc = REXML::Document.new(body)

    # RSS 2.0: look for <description> with price pattern
    REXML::XPath.each(doc, "//item/description") do |elem|
      text = elem.text.to_s
      price = extract_decimal(text)
      return price if price
    end

    # RSS 2.0: look in <title>
    REXML::XPath.each(doc, "//item/title") do |elem|
      text = elem.text.to_s
      price = extract_decimal(text)
      return price if price
    end

    # Atom: look in <entry><content> or <entry><summary>
    REXML::XPath.each(doc, "//entry/content | //entry/summary") do |elem|
      text = elem.text.to_s
      price = extract_decimal(text)
      return price if price
    end

    # Generic: look for <price> element
    REXML::XPath.each(doc, "//price") do |elem|
      return elem.text.to_f if elem.text
    end

    nil
  rescue REXML::ParseException
    nil
  end

  def self.extract_price_from_html(body)
    # Try JSON-LD script tag first
    script_match = body.match(%r{<script type="application/ld\+json">(.+?)</script>}m)
    if script_match
      price = extract_price_from_json(script_match[1])
      return price if price
    end

    # Try common price CSS patterns
    patterns = [
      # StatusInvest: <strong class="value"> or data attributes
      %r{<strong[^>]*class="[^"]*value[^"]*"[^>]*>([\d.,]+)\s*</strong>}im,
      # Fundamentus: table cell with price
      %r{<span[^>]*class="[^"]*txt[^"]*"[^>]*>R?\$?\s*([\d.,]+)\s*</span>}im,
      # Generic: price in element with "price" class
      %r{class="[^"]*price[^"]*"[^>]*>\s*R?\$?\s*([\d.,]+)\s*}im,
      # Meta property
      %r{<meta[^>]*property="[^"]*price[^"]*"[^>]*content="([\d.]+)"}im,
      # Generic number with R$ prefix
      %r{R\$\s*([\d.,]+)}im
    ]

    patterns.each do |pattern|
      match = body.match(pattern)
      if match
        price = parse_br_decimal(match[1])
        return price if price && price > 0
      end
    end

    nil
  end

  def self.extract_price_from_csv(body)
    rows = CSV.parse(body, col_sep: ";")
    # If single column, try comma separator
    if rows.all? { |r| r.size == 1 }
      rows = CSV.parse(body, col_sep: ",")
    end

    rows.each do |row|
      row.each do |cell|
        next unless cell
        cleaned = cell.strip.gsub("R$", "").gsub(/["'$]/, "").strip
        if cleaned.match?(/\A-?\d+[.,]\d+\z/)
          price = parse_br_decimal(cleaned)
          return price if price && price > 0
        end
      end
    end
    nil
  rescue CSV::MalformedCSVError
    nil
  end

  def self.extract_price_with_regex(body)
    # Look for "R$ 123,45" or "123.45" patterns
    price_match = body.match(/R\$\s*([\d.,]+)/)
    return parse_br_decimal(price_match[1]) if price_match

    # Generic decimal extraction
    decimal_match = body.match(/(\d+[.,]\d{2})\b/)
    return parse_br_decimal(decimal_match[1]) if decimal_match

    nil
  end

  # ── Helpers ─────────────────────────────────────────────────────

  def self.parse_br_decimal(str)
    return nil if str.blank?

    # Brazilian format: 1.234,56 → 1234.56
    cleaned = str.strip.gsub(/[R$\s]/, "")

    if cleaned.include?(".") && cleaned.include?(",")
      # 1.234,56
      cleaned = cleaned.gsub(".", "").gsub(",", ".")
    elsif cleaned.include?(",") && !cleaned.include?(".")
      # 1234,56
      cleaned = cleaned.gsub(",", ".")
    end

    cleaned.to_f
  end

  def self.extract_decimal(text)
    match = text.match(/(\d+[.,]\d{2})/)
    match ? parse_br_decimal(match[1]) : nil
  end
end
