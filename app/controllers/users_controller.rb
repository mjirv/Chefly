class UsersController < ApplicationController
    # Makes sure the right user is logged in
    before_filter -> { authorize_id(params[:id]) }, except: [:new, :create, :autocomplete_tag_name]
    autocomplete :tag, :name

    def new
        @user = User.new
    end
  
    def create
        @user = User.new(user_params)
        @user.status = User.statuses["active"]
        # What if we want to create an admin? Right now, we have to use the rails console
        @user.permission = User.permissions["user"]
        if @user.save
            session[:user_id] = @user.id
            redirect_to dashboard_path(@user.id)
        else
            flash.alert = "An error occurred."
            redirect_to '/signup'
        end
    end

    def show
        @user = User.find(params[:id])
    end

    def update
        @user = User.find(params[:id])
    end

    # The edit profile form calls this
    def edit_save
        @user = User.find(params[:id])
        if @user.authenticate(user_params[:password]) && @user.update(user_params)
            flash.notice = 'Successfully updated your profile.'
        else
            flash.notice = 'Something went wrong.'
        end
        redirect_to edit_user_path(@user.id)
    end

    def change_password
        @user = User.find(params[:id])
    end

    # Called by submitting change password form
    def change_password_save
        @user = User.find(params[:id])
        # Make sure the user confirmed the new password and entered the correct previous one
        if user_params[:new_password] == user_params[:password_confirmation] && @user.authenticate(user_params[:password]) && @user.update(:password => user_params[:new_password])
            flash.notice = 'Successfully updated your password.'
            redirect_to edit_users_path(@user.id)
        else
            flash.notice = 'You did not provide the right current password, or the new password you entered does not match the confirmation.'
            redirect_to change_password_path(@user.id)
        end
    end

    private
    # Get the params in a secure way
    def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :status, :permission, :password_confirmation, :new_password)
    end

end
