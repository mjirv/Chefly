class SessionsController < ApplicationController
    # Do I need this?
    def new
    end

    # Called when a user logs in (i.e. creates a session)
    def create
        @user = User.find_by_email(params[:session][:email])
        if @user && @user.authenticate(params[:session][:password])
            session[:user_id] = @user.id
            redirect_to dashboard_path(@user.id)
        else
            flash.notice = "Incorrect username or password."
            redirect_to '/login'
        end
    end

    def destroy
        session[:user_id] = nil
        redirect_to '/'
    end
end