require_relative 'config/environment'
puts ActiveRecord::Base.connection.tables.inspect
