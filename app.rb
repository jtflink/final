# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
require "geocoder"                                                                    #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

places_table = DB.from(:places)
recommendations_table = DB.from(:recommendations)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# index
get "/" do
    puts "params: #{params}"

    @places = places_table.all.to_a
    pp @places

    view "places"
end

post "/send_text" do
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]

    client = Twilio::REST::Client.new(account_sid, auth_token)

    client.messages.create(
        from: "+12065392812", 
        to: "+17134100878",
        body: "This app is great!"
    )

    redirect "/"
end 

# place details
get "/places/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @place = places_table.where(id: params[:id]).to_a[0]
    pp @place

    @recommendations = recommendations_table.where(place_id: @place[:id]).to_a
    
    @lat_long = places_table.where(id: params[:id]).to_a[0][:lat_long]

    view "place"
end

# receive the submitted places form
post "/places/create" do
    puts "params: #{params}"

    existing_place = places_table.where(title: params["place"]).to_a[0]
    if existing_place
        view "existing_place_error"
    else
        results = Geocoder.search(params["place"])
        lat_long = results.first.coordinates
        @lat_lng = "#{lat_long[0]},#{lat_long[1]}" 

        places_table.insert(
            title: params["place"],
            lat_long: @lat_lng
        )

        redirect "/"
    end
end

# display the recommendations form
get "/places/:id/recommendations/new" do
    puts "params: #{params}"

    @place = places_table.where(id: params[:id]).to_a[0]
    view "new_recommendation"
end

get "/new_place" do
    view "new_place"
end

# receive the submitted recommendations form
post "/places/:id/recommendations/create" do
    puts "params: #{params}"

    @place = places_table.where(id: params[:id]).to_a[0]
    recommendations_table.insert(
        place_id: @place[:id],
        user_id: session["user_id"],
        recommendations: params["recommendations"]
    )

    redirect "/places/#{@place[:id]}"
end

# delete the recommendation
get "/recommendations/:id/destroy" do
    puts "params: #{params}"

    recommendation = recommendations_table.where(id: params["id"]).to_a[0]
    @place = places_table.where(id: recommendation[:place_id]).to_a[0]

    recommendations_table.where(id: params["id"]).delete

    redirect "/places/#{@place[:id]}"
end

# display the signup form
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form
post "/users/create" do
    puts "params: #{params}"

    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form
post "/logins/create" do
    puts "params: #{params}"

    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        if BCrypt::Password.new(@user[:password]) == params["password"]
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    session["user_id"] = nil
    redirect "/logins/new"
end