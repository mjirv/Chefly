class UsersController < ApplicationController
	def show
		@user = User.find(params[:id])
	end

	def update
		@user = User.find(params[:id])
	end

	def show_recipes
		@user = User.find(params[:id])
		@recipes = Recipe.where(:id => RecipeToUserLink.where(:user_id => @user.id).where(:status => RecipeToUserLink.statuses["active"]).pluck(:recipe_id))
	end

	def config_recipe_generation
		@user = User.find(params[:id])
		@options = (1..10).to_a
	end

	def generate_recipes
		user_id = params[:id]
		n_recipes = params[:Config][:n_recipes]
		old_recipes = RecipeToUserLink.where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"])

		old_recipes.map{ |r| r.status = RecipeToUserLink.statuses["inactive"] }
		old_recipes.map{ |r| r.save }

	  	recipes = Recipe.limit(n_recipes).order("RANDOM()")
	  	recipes.each do |recipe|
	  		link = RecipeToUserLink.new(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe.id)
	  		link.save
	  	end

	  	generate_grocery_list(user_id)
	end

	def generate_grocery_list(user_id)
  		if GroceryList.where(:user_id => user_id).where(:status => GroceryList.statuses["active"]) != []
	  		GroceryList.where(:user_id => user_id).map do |g| 
	  			g.status = GroceryList.statuses["inactive"]
	  			g.save
	  		end
	  	end

  		recipe_items = RecipeItem.where(:recipe_id => Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id)))
	  	grocery_list = GroceryList.create(:user_id => user_id, :status => GroceryList.statuses["active"])

  		recipe_items.each do |ri|
  			item_name = ri.item.name
  			if item_name.match(/[a-z]+/) # TODO: and doesn't end in a colon
	  			unit_name = ri.quantity.unit.name
	  			list_key = "#{unit_name} #{item_name}"
	  			amount = ri.quantity.amount

	  			if unit_name == "NULL_UNIT"
	  				amount = ""
	  				list_key = "#{item_name}"
	  			end

	  			grocery_list.add_to_list(list_key, amount)
	  		end
  		end
  		grocery_list.save_list
  		redirect_to show_user_recipes_path, :method => :get
	end

end