class SessionsController < ApplicationController
    # Do I need this?
    def new
    end

    # Called when a user logs in (i.e. creates a session)
    def create
        @user = User.find_by_email(params[:session][:email])
        if @user && @user.authenticate(params[:session][:password])
            cookies.signed[:user_id] = @user.id
            redirect_to dashboard_path(@user.id)
        else
            flash.notice = "Incorrect username or password."
            redirect_to '/login'
        end
    end

    def create
        if user = authenticate_via_google
            cookies.signed[:user_id] = user.id
            redirect_to dashboard_path(user.id)
        elsif user = create_user_via_google
            cookies.signed[:user_id] = user.id
            redirect_to dashboard_path(user.id)
        else
            flash.notice = "Login failed, please try again."
            redirect_to login_path
        end
    end

    def destroy
        cookies.signed[:user_id] = nil
        redirect_to '/'
    end

    private
    def authenticate_via_google
        if params[:google_id_token].present?
            User.find_by google_id: GoogleSignIn::Identity.new(params[:google_id_token]).user_id
        end
    end

    def create_user_via_google
        if params[:google_id_token].present?
            identity = GoogleSignIn::Identity.new(params[:google_id_token])
            User.create!(name: identity.name, email: identity.email_address, google_id: identity.user_id)
        end
    end
end