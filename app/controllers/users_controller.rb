class UsersController < ApplicationController
	before_filter -> { authorize_id(params[:id]) }, except: [:new, :create]

	def new
    	@user = User.new
 	end
  
  	def create
	    @user = User.new(user_params)
	    @user.status = User.statuses["active"]
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

	def edit_save
		@user = User.find(params[:id])
	    if @user.authenticate(user_params[:password]) && @user.update(user_params)
			flash.notice = 'Successfully updated your profile.'
		else
			flash.notice = 'Something went wrong.'
		end
		redirect_to edit_user_path(@user.id)
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

	  	generate_grocery_list(user_id, "no_redirect")
	  	redirect_to show_user_recipes_path(:id => user_id), :method => :get
	end

	def generate_grocery_list(user_id = false, redirect_to_gl=false)
		if not user_id
			user_id = params[:id]
		end
		if not redirect_to_gl
			redirect_to_gl = params[:redirect_to_gl]
		end
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
  			if item_name.match(/[a-z]+/) && item_name[-1] != ":"
	  			unit_name = ri.quantity.unit.name

	  			gli_name = "#{unit_name} #{item_name}"
	  			amount = ri.quantity.amount
	  			recipe_item_id = ri.id
	  			grocery_list_id = grocery_list.id


	  			if unit_name == "NULL_UNIT"
	  				amount = 1.0
	  				gli_name = "#{item_name}"
	  			end

	  			string_amount = amount.to_s

	  			GroceryListItem.create(:name => gli_name, :amount => amount, :string_amount => string_amount, :recipe_item_id => recipe_item_id, :grocery_list_id => grocery_list_id)
	  		end
  		end
  		grocery_list.deduplicate

  		if redirect_to_gl == "true"
  			redirect_to grocery_list_path(grocery_list.id)
  		end
	end

	def generate_recipe
		user_id = User.find(params[:id]).id
		num_recipes = Recipe.all.count
		recipe_ids = Recipe.all.pluck(:id)

		# Make sure we aren't duplicating recipes
		if RecipeToUserLink.where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"]).count == num_recipes
			raise RuntimeError, "No more recipes available"
		end
		recipe = Recipe.find(recipe_ids.sample)
		while RecipeToUserLink.where(:user_id => user_id).where(:recipe_id => recipe.id).where(:status => RecipeToUserLink.statuses["active"]) != []
			recipe = Recipe.find(Random.rand(num_recipes))
		end

		link = RecipeToUserLink.create(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe.id)
		generate_grocery_list(user_id)
		redirect_to show_user_recipes_path(user_id)
	end

	def delete_recipe
		delete_recipe_helper(params[:id], params[:recipe_id])
		generate_grocery_list(params[:id])
		redirect_to show_user_recipes_path(params[:id])
	end

	def delete_and_generate_recipe
		delete_recipe_helper(params[:id], params[:recipe_id])
		generate_recipe
	end

	def auto_instacart
		item_hash = Hash.new(0)
		grocery_list = GroceryList.find(params[:grocery_list_id].to_i)
		grocery_list.grocery_list_items.each do |item|
			item_hash[item.recipe_item.item.name] += item.recipe_item.item_amount.ceil
		end

		item_hash_str = item_hash.to_s.gsub("\"", "'").gsub("=>", ":")
		print item_hash_str
		instacart_joiner_path = Rails.root.join('lib', 'utilities', 'instacart_driver.py').to_s
		print instacart_joiner_path
		`python "#{instacart_joiner_path}" #{ENV["INSTACART_USER"]} #{ENV["INSTACART_PASS"]} "#{item_hash_str}" "#{ENV["CHROMEDRIVER_PATH"]}"`

		redirect_to dashboard_path(params[:id])
	end

	def change_password
		@user = User.find(params[:id])
	end

	def change_password_save
		@user = User.find(params[:id])
	    if user_params[:new_password] == user_params[:password_confirmation] && @user.authenticate(user_params[:password]) && @user.update(:password => user_params[:new_password])
			flash.notice = 'Successfully updated your password.'
			redirect_to edit_users_path(@user.id)
		else
			flash.notice = 'You did not provide the right current password, or the new password you entered does not match the confirmation.'
			redirect_to change_password_path(@user.id)
		end
	end

	private
	def delete_recipe_helper(user_id, recipe_id)
		user_recipe = RecipeToUserLink.where(:recipe_id => recipe_id).where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"])
		if user_recipe == []
			raise ArgumentError, "Recipe does not exist or is already deleted."
		else
			user_recipe = user_recipe.first
			user_recipe.status = RecipeToUserLink.statuses["inactive"]
			user_recipe.save
		end
	end

  	def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :status, :permission, :password_confirmation, :new_password)
    end

end