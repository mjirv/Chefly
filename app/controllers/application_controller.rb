class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def authorize
    if not current_user
        flash.notice('You must be logged in to access that page.')
        redirect_to '/login' unless current_user
    end
  end

  def authorize_id user_id
    if current_user
        raise Exception, "You are not authorized to view this page." unless session[:user_id] == user_id.to_i || User.find(session[:user_id]).permission == "admin"
    else
        flash.notice('You must be logged in to access that page.')
        redirect_to '/login'
    end
  end

  def authorize_admin
    if current_user
        raise Exception, "You are not authorized to view this page." unless User.find(session[:user_id]).permission == "admin"
    else
        flash.notice('You must be logged in to access that page.')
        redirect_to '/login'
    end
  end
end
