require "rss"
require "open-uri"

class NewsFeedService
  CACHE_KEY = "news_feed_articles"
  CACHE_TTL = 30.minutes

  FEEDS = ENV.fetch("NEWS_FEED_URLS", "").split(",").presence || [
    "https://www.infomoney.com.br/feed/",
    "https://valor.globo.com/rss/valor/",
    "https://investnews.com.br/feed/"
  ]

  def self.fetch_latest(limit = 10)
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      articles = []

      FEEDS.each do |url|
        begin
          URI.open(url) do |rss|
            feed = RSS::Parser.parse(rss)
            feed.items.each do |item|
              articles << {
                title: item.title,
                link: item.link,
                pub_date: item.pubDate,
                source: feed.channel.title
              }
            end
          end
        rescue StandardError => e
          Rails.logger.error "NewsFeedService Error for #{url}: #{e.message}"
        end
      end

      articles.sort_by { |a| a[:pub_date] }.reverse.take(limit)
    end
  end
end
