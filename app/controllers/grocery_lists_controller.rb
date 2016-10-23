require 'mail'
require "net/https"
require "uri"


class GroceryListsController < ApplicationController
	before_filter -> { authorize_id(GroceryList.find(params[:id]).user_id) }

	def show
		@grocery_list = GroceryList.find(params[:id])
	end

	def update
		@grocery_list = GroceryList.find(params[:id])
	end

	def email
		@grocery_list = GroceryList.find(params[:id])
		user_id = @grocery_list.user_id
		user_email = User.find(user_id).email
	  	recipes = Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id))
	  	message = ""

	  	recipes.each do |recipe|
	  		message << 
			"<b>#{recipe.name}</b>
			<br />#{recipe.recipe_items.pluck(:name).join("<br />")}
			<br />#{recipe.url}
			<br /><br />"
	  	end

	  	message <<
		"<b>Shopping List</b>
		<br />#{@grocery_list.get_list.join("<br />")}"

	  	puts "Email: #{ENV["FROM_EMAIL"]}"

	  	options = { :address => 'smtp.gmail.com',
	  				:port => 587,
	  				:domain => 'gmail.com',
	  				:user_name => ENV["FROM_EMAIL"],
	  				:password => ENV["FROM_EMAIL_PASSWORD"],
	  				:authentication => 'plain',
	  				:enable_starttls_auto => true }

	  	Mail.defaults do
	  		delivery_method :smtp, options
	  	end

	  	Mail.deliver do 
	  		content_type 'text/html; charset=UTF-8'
	  		to user_email
	  		from  "Michael's Recipe App #{ENV['FROM_EMAIL']}"
	  		subject "Your recipes for the week are ready!"
	  		body message
	  	end

	  	redirect_to dashboard_path(user_id)
	end

	def item_mapping
		# TODO make it so only the admin can access this
		@grocery_list = GroceryList.find(params[:id])
		@grocery_list_items = GroceryListItem.where(:grocery_list_id => params[:id]).where.not(:visible => false)
	end

	def update_and_show
		grocery_list = GroceryList.find(params[:id])
		user = grocery_list.user_id
		grocery_list.deduplicate()
		grocery_list.regenerate_items()
		redirect_to grocery_list_path(params[:id])
	end

	private
	def add_item_to_instacart(item)
		uri = URI.parse("https://instacart.com/")
	end
end
