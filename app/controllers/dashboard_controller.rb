class DashboardController < ApplicationController
	def show
		@user = User.find(params[:id])
		@grocery_list_id = GroceryList.where(:user_id => @user.id).where(:status => GroceryList.statuses["active"]).first.id rescue 0 #TODO change this
	end
end