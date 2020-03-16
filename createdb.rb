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
recommendations_table = DB.from(:recommendations)
users_table = DB.from(:users)

places_table.insert(id: 0,
                    title: "Chicago",
                    description: "something",
                    address: "address")

recommendations_table.insert(id: 0,
                    place_id: 0,
                    user_id: 0,
                    recommendations: "Such a great city!")

users_table.insert(id: 0,
                    name: "Jordan", 
                    email: "test@test.com",
                    password: "test")

puts "Success!" 