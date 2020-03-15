# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :places do
  primary_key :id
  String :title
  String :description, text: true
  String :address
end
DB.create_table! :recommendations do
  primary_key :id
  foreign_key :place_id
  foreign_key :user_id
  String :recommendations, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
places_table = DB.from(:places)

places_table.insert(title: "Chicago", 
                    description: "The Windy City",
                    address: "Somewhere")

recommendations_table = DB.from(:recommendations)

recommendations_table.insert(recommendations: "There are so many fun things to do in Chicago!")

puts "Success!" 