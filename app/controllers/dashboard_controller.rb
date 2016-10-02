class DashboardController < ApplicationController
	def show
		@user = User.find(params[:id])
		@grocery_list = GroceryList.where(:user_id => @user.id).where(:status => GroceryList.statuses["active"]).first
	end
end