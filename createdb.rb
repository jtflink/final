# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :places do
  primary_key :id
  String :title
  String :lat_long
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
                    title: "Evanston",
                    lat_long: "42.0451,-87.6877")

places_table.insert(id: 1,
                    title: "Chicago",
                    lat_long: "41.8781,-87.6298")

places_table.insert(id: 2,
                    title: "San Francisco",
                    lat_long: "37.7749,-122.4194")

recommendations_table.insert(id: 0,
                    place_id: 0,
                    user_id: 0,
                    recommendations: "There are so many things to do in Evanston!")

recommendations_table.insert(id: 1,
                    place_id: 1,
                    user_id: 0,
                    recommendations: "Chicago, the Windy City, has so many things to do. One of the best things to do in the city is to visit Navy Pier.")

recommendations_table.insert(id: 2,
                    place_id: 2,
                    user_id: 0,
                    recommendations: "One of the best things to do in San Francisco is to visit Golden Gate Park.")

users_table.insert(id: 0,
                    name: "Jordan", 
                    email: "test@test.com",
                    password: "test")

puts "Success!" 