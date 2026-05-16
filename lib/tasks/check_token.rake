task check_token: :environment do
  puts "ENV['BRAPI_TOKEN']: \#{ENV['BRAPI_TOKEN'].inspect}"
end
