class DashboardController < ApplicationController
    before_filter -> { authorize_id(params[:id]) }

    # Get the variables needed to show the dashboard
	def show
		@user = User.find(params[:id])
		@grocery_list_id = GroceryList.where(:user_id => @user.id).where(:status => GroceryList.statuses["active"]).first.id rescue 0
        # Why is this how we check that there's a grocery list?
        @grocery_list = @grocery_list_id > 0
        @recipes_length = RecipeToUserLink.where(:user_id => @user.id).where(:status => RecipeToUserLink.statuses["active"]).count
	end
end