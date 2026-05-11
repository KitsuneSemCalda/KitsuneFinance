require "test_helper"

class PriceServiceTest < ActiveSupport::TestCase
  test "parse_br_decimal converts Brazilian format" do
    assert_equal 1234.56, PriceService.parse_br_decimal("1.234,56")
    assert_equal 1234.56, PriceService.parse_br_decimal("1234,56")
    assert_equal 1234.56, PriceService.parse_br_decimal("1234.56")
    assert_equal 25.50, PriceService.parse_br_decimal("25,50")
    assert_equal 25.50, PriceService.parse_br_decimal("R$ 25,50")
    assert_nil PriceService.parse_br_decimal("")
    assert_nil PriceService.parse_br_decimal(nil)
  end

  test "fetch_price returns nil for blank ticker" do
    assert_nil PriceService.fetch_price("", "stock_br")
    assert_nil PriceService.fetch_price(nil, "stock_br")
  end

  test "fetch_price uses price_feed_url when provided" do
    called_with_url = nil
    stub_method(PriceService, :fetch_from_custom_url, ->(url) {
      called_with_url = url; 42.0
    }) do
      price = PriceService.fetch_price("PETR4", "stock_br", nil, price_feed_url: "https://example.com/feed")
      assert_equal 42.0, price
      assert_equal "https://example.com/feed", called_with_url
    end
  end

  test "fetch_price falls back to provider chain when feed_url returns nil" do
    stub_method(PriceService, :fetch_from_custom_url, ->(*) { nil }) do
      stub_method(PriceService, :fetch_br_price, ->(*) { 25.0 }) do
        price = PriceService.fetch_price("PETR4", "stock_br", nil, price_feed_url: "https://example.com")
        assert_equal 25.0, price
      end
    end
  end

  test "fetch_price returns alpha_vantage as universal fallback" do
    stub_method(PriceService, :fetch_from_custom_url, ->(*) { nil }) do
      stub_method(PriceService, :fetch_br_price, ->(*) { nil }) do
        stub_method(PriceService, :fetch_alpha_vantage_price, ->(*) { 30.0 }) do
          price = PriceService.fetch_price("PETR4", "stock_br", nil)
          assert_equal 30.0, price
        end
      end
    end
  end

  test "fetch_br_price fallback chain" do
    # Test that it goes through the full chain and returns the first hit
    stub_method(PriceService, :fetch_brapi_price, ->(*) { nil }) do
      stub_method(PriceService, :fetch_yahoo_price, ->(*) { nil }) do
        stub_method(PriceService, :fetch_alpha_vantage_price, ->(*) { nil }) do
          stub_method(PriceService, :fetch_statusinvest_price, ->(*) { nil }) do
            stub_method(PriceService, :fetch_fundamentus_price, ->(*) { 15.5 }) do
              price = PriceService.fetch_br_price("PETR4", nil)
              assert_equal 15.5, price
            end
          end
        end
      end
    end
  end

  test "fetch_br_price returns brapi price first" do
    stub_method(PriceService, :fetch_brapi_price, ->(*) { 20.0 }) do
      stub_method(PriceService, :fetch_yahoo_price, ->(*) { flunk "should not reach yahoo" }) do
        stub_method(PriceService, :fetch_alpha_vantage_price, ->(*) { flunk "should not reach alpha vantage" }) do
          stub_method(PriceService, :fetch_statusinvest_price, ->(*) { flunk "should not reach statusinvest" }) do
            stub_method(PriceService, :fetch_fundamentus_price, ->(*) { flunk "should not reach fundamentus" }) do
              assert_equal 20.0, PriceService.fetch_br_price("PETR4", "token")
            end
          end
        end
      end
    end
  end

  test "extract_price_from_json handles various API formats" do
    # brapi format
    assert_equal 25.5, PriceService.extract_price_from_json(%({"results":[{"regularMarketPrice":25.5}]}))
    # Alpha Vantage format
    assert_equal 150.0, PriceService.extract_price_from_json(%({"Global Quote": {"05. price": "150.00"}}))
    # Simple format
    assert_equal 42.0, PriceService.extract_price_from_json(%({"price": 42.0}))
    # Yahoo format
    assert_equal 180.0, PriceService.extract_price_from_json(%({"chart":{"result":[{"meta":{"regularMarketPrice":180.0}}]}}))
    # Invalid JSON
    assert_nil PriceService.extract_price_from_json("invalid")
  end

  test "extract_price_from_html handles StatusInvest and Fundamentus" do
    # StatusInvest format
    html = '<strong class="value">R$ 25,50</strong>'
    assert_equal 25.50, PriceService.extract_price_from_html(html)

    # Fundamentus format (with span)
    html2 = '<span class="txt">R$ 34,56</span>'
    assert_equal 34.56, PriceService.extract_price_from_html(html2)

    # Generic price class
    html3 = '<div class="price">R$ 100,00</div>'
    assert_equal 100.0, PriceService.extract_price_from_html(html3)

    # JSON-LD embedded
    html4 = '<script type="application/ld+json">{"price": 50.0}</script>'
    assert_equal 50.0, PriceService.extract_price_from_html(html4)

    # No price info
    assert_nil PriceService.extract_price_from_html("<html><body>No price here</body></html>")
  end

  test "extract_price_from_xml parses RSS feeds" do
    rss = <<~XML
      <?xml version="1.0"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>Stock ABC at R$ 45,67</title>
            <description>Today the stock price is 45.67</description>
          </item>
        </channel>
      </rss>
    XML
    assert_equal 45.67, PriceService.extract_price_from_xml(rss)

    # Atom format
    atom = <<~XML
      <?xml version="1.0"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <content>Price: R$ 78,90</content>
        </entry>
      </feed>
    XML
    assert_equal 78.90, PriceService.extract_price_from_xml(atom)

    # No price
    assert_nil PriceService.extract_price_from_xml("<xml><item><title>Hello</title></item></xml>")

    # Invalid XML
    assert_nil PriceService.extract_price_from_xml("not xml")
  end

  test "extract_price_from_csv parses CSV" do
    csv = "Ticker;Price\nPETR4;25,50\n"
    assert_equal 25.50, PriceService.extract_price_from_csv(csv)

    csv2 = "Ticker,Price\nPETR4,25.50\n"
    assert_equal 25.50, PriceService.extract_price_from_csv(csv2)

    csv3 = "col1;col2\nabc;def\n"
    assert_nil PriceService.extract_price_from_csv(csv3)
  end

  test "fetch_from_custom_url handles JSON API" do
    response = OpenStruct.new(
      success?: true,
      body: '{"price": 42.50}',
      headers: { "content-type" => "application/json" }
    )
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal 42.50, PriceService.fetch_from_custom_url("https://api.example.com/price")
    end
  end

  test "fetch_from_custom_url handles RSS feed" do
    rss_body = <<~XML
      <?xml version="1.0"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>Cotação: R$ 33,00</title>
          </item>
        </channel>
      </rss>
    XML
    response = OpenStruct.new(
      success?: true,
      body: rss_body,
      headers: { "content-type" => "application/rss+xml" }
    )
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal 33.0, PriceService.fetch_from_custom_url("https://example.com/feed.rss")
    end
  end

  test "fetch_from_custom_url handles HTML page" do
    html = '<html><body><div class="price">R$ 55,00</div></body></html>'
    response = OpenStruct.new(
      success?: true,
      body: html,
      headers: { "content-type" => "text/html" }
    )
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal 55.0, PriceService.fetch_from_custom_url("https://example.com/price.html")
    end
  end

  test "fetch_from_custom_url returns nil on failure" do
    response = OpenStruct.new(success?: false)
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_nil PriceService.fetch_from_custom_url("https://example.com/price")
    end
  end

  test "fetch_from_custom_url returns nil for blank url" do
    assert_nil PriceService.fetch_from_custom_url("")
    assert_nil PriceService.fetch_from_custom_url(nil)
  end

  test "fetch_alpha_vantage_price returns nil without API key" do
    with_env("ALPHA_VANTAGE_KEY", nil) do
      assert_nil PriceService.fetch_alpha_vantage_price("PETR4")
    end
  end

  test "fetch_alpha_vantage_price parses response" do
    with_env("ALPHA_VANTAGE_KEY", "demo") do
      response = OpenStruct.new(
        success?: true,
        body: '{"Global Quote": {"05. price": "150.00"}}'
      )
      stub_method(Faraday, :get, ->(*) { response }) do
        assert_equal 150.0, PriceService.fetch_alpha_vantage_price("AAPL")
      end
    end
  end

  private

  def with_env(key, value)
    old = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = old
  end
end
