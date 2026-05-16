require "test_helper"

class NewsFeedServiceTest < ActiveSupport::TestCase
  RSS_XML = <<~XML
    <?xml version="1.0"?>
    <rss version="2.0">
      <channel>
        <title>InfoMoney</title>
        <link>https://example.com</link>
        <description>Financial news</description>
        <item>
          <title>Bolsa fecha em alta</title>
          <link>https://example.com/artigo1</link>
          <description>Market up</description>
          <pubDate>Mon, 15 May 2026 10:00:00 GMT</pubDate>
        </item>
        <item>
          <title>Dólar cai</title>
          <link>https://example.com/artigo2</link>
          <description>Dollar down</description>
          <pubDate>Sun, 14 May 2026 15:30:00 GMT</pubDate>
        </item>
      </channel>
    </rss>
  XML

  test "fetch_latest returns parsed articles sorted by date" do
    stub_method(URI, :open, ->(url, &block) { block.call(StringIO.new(RSS_XML)) }) do
      stub_method(Rails.logger, :error, ->(*) { }) do
        articles = NewsFeedService.fetch_latest(10)
        assert_equal 6, articles.length
        assert_equal "Bolsa fecha em alta", articles[0][:title]
        assert_equal "InfoMoney", articles[0][:source]
      end
    end
  end

  test "fetch_latest respects limit" do
    stub_method(URI, :open, ->(url, &block) { block.call(StringIO.new(RSS_XML)) }) do
      stub_method(Rails.logger, :error, ->(*) { }) do
        articles = NewsFeedService.fetch_latest(1)
        assert_equal 1, articles.length
      end
    end
  end

  test "fetch_latest handles RSS parse error gracefully" do
    stub_method(URI, :open, ->(url, &block) { block.call(StringIO.new("invalid xml")) }) do
      stub_method(Rails.logger, :error, ->(*) { }) do
        articles = NewsFeedService.fetch_latest(10)
        assert_equal [], articles
      end
    end
  end

  test "fetch_latest handles network error gracefully" do
    stub_method(URI, :open, ->(*, **) { raise Errno::ECONNREFUSED }) do
      stub_method(Rails.logger, :error, ->(*) { }) do
        articles = NewsFeedService.fetch_latest(10)
        assert_equal [], articles
      end
    end
  end
end
