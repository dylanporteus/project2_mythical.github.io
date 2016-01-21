require "sinatra/base"
require "pg"
require "bcrypt"



	class Server < Sinatra::Base
		enable :sessions
		set :method_override, true

		@@db = PG.connect(dbname: "mythical_db_test")

		def current_user
			if session["user_id"]
				@user ||= @@db.exec_params(<<-SQL, [session["user_id"]]).first
				  SELECT * FROM users WHERE id = $2
				SQL
			else
				#The empty object will signify that a user is not logged in.
			   {}
			end
		end


		get "/" do 
			redirect "/signup"
		end

		get "/signup" do 
			erb :signup
		end

		post "/signup" do 
			encrypted_password = BCrypt::Password.create(params[:login_password])

			users = @@db.exec_params(<<-SQL, [params[:email], params[:username], encrypted_password])
			  INSERT INTO users (email, username, password_digest) VALUES ($1, $2, $3) RETURNING id;
			SQL

			session["user_id"] = users.first["id"]

			erb :signup_success

		end


		get "/login" do 
           erb :login 
		end

		post "/login" do
         @user = @@db.exec_params("SELECT * FROM users WHERE username = $1", [params[:login_name]]).first
         if @user 
         	if BCrypt::Password.new(@user["password_digest"]) == params[:login_password]
         	  session["user_id"] = @user["id"]
         	  redirect "/"
         	else
         		@error = "Invalid Password"
         		erb :login 
         	end
         else
         	@error = "Invalid Username"
         	erb :login 
         end
		end



		
	end



