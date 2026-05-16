class AddPriceFeedUrlToInvestments < ActiveRecord::Migration[8.1]
  def change
    add_column :investments, :price_feed_url, :string
  end
end
