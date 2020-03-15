# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
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

# place details
get "/places/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @place = places_table.where(id: params[:id]).to_a[0]
    pp @place

    @recommendations = recommendations_table.where(place_id: @place[:id]).to_a
    @recommendations_count = recommendations_table.where(event_id: @place[:id], going: true).count

    view "place"
end

# display the recommendations form
get "/places/:id/recommendations/new" do
    puts "params: #{params}"

    @place = places_table.where(id: params[:id]).to_a[0]
    view "new_recommendation"
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

# display the recommendations form
get "/recommendations/:id/edit" do
    puts "params: #{params}"

    @recommendation = recommendations_table.where(id: params["id"]).to_a[0]
    @place = places_table.where(id: @recommendation[:place_id]).to_a[0]
    view "edit_recommendation"
end

# receive the submitted recommendation form
post "/recommendations/:id/update" do
    puts "params: #{params}"

    @recommendation = recommendations_table.where(id: params["id"]).to_a[0]
    @place = places_table.where(id: @recommendation[:place_id]).to_a[0]

    if @current_user && @current_user[:id] == @recommendation[:id]
        recommendations_table.where(id: params["id"]).update(
            recommendations: params["recommendations"]
        )

        redirect "/places/#{@place[:id]}"
    else
        view "error"
    end
end

# delete the recommendation
get "/recommendations/:id/destroy" do
    puts "params: #{params}"

    recommendation = recommendations_table.where(id: params["id"]).to_a[0]
    @place = places_table.where(id: recommendation[:place_id]).to_a[0]

    recommendations_table.where(id: params["id"]).delete

    redirect "/places/#{@place[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
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

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
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
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end

