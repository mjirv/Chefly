require 'mail'

namespace :send_recipes do
  desc "Creates five new recipes for a user and deactivates old ones"
  task :get_recipes_for_user, [:user_email, :n_recipes] => [:environment] do |t, args|
  	begin
  		user_id = User.where(:email => args.user_email).first.id

	  	# Get rid of last week's recipes
	  	# TODO: separate this part out to its own task when giving user ability to review recipes
	  	last_week_recipes = RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id)
	  	last_week_recipes.map{ |r| r.status = RecipeToUserLink.statuses["inactive"]}
	  	last_week_recipes.map{ |r| r.save }

	  	# Get some new random ones!
	  	recipes = Recipe.limit(args.n_recipes).order("RANDOM()")
	  	recipes.each do |recipe|
	  		link = RecipeToUserLink.new(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe.id)
	  		link.save
	  		puts recipe.recipe_items.pluck(:name)
	  		puts recipe.url
	  		puts ""
  		end
  	rescue
  		puts "User does not exist." #TODO: check that that's actually the error and handle it better
  	end
  end

  desc "Generates a grocery list from the user's active recipes"
  task :generate_grocery_list, [:user_email] => [:environment] do |t, args|
  	begin
  		user_id = User.where(:email => args.user_email).first.id

  		# Deactivate old grocery lists
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
  		puts grocery_list.get_list
	rescue
		puts "User does not exist."
	end
  end

  desc "Sends a user's active recipes to them"
  task :send_recipes_to_user, [:user_email, :from_email, :from_password] => [:environment] do |t, args|
  	#begin
	  	user_id = User.where(:email => args.user_email).first.id
	  	recipes = Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id))
	  	grocery_list = GroceryList.where(:user_id => user_id, :status => GroceryList.statuses["active"]).first
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
		<br />#{grocery_list.get_list.join("<br />")}"
	  	puts message

	  	options = { :address => 'smtp.gmail.com',
	  				:port => 587,
	  				:domain => 'gmail.com',
	  				:user_name => args.from_email,
	  				:password => args.from_password,
	  				:authentication => 'plain',
	  				:enable_starttls_auto => true }

	  	Mail.defaults do
	  		delivery_method :smtp, options
	  	end

	  	Mail.deliver do 
	  		content_type 'text/html; charset=UTF-8'
	  		to args.user_email
	  		from  "Michael's Recipe App #{args.from_email}"
	  		subject "Your recipes for the week are ready!"
	  		body message
	  	end
	#rescue
		puts "User does not exist."
	#end
  end
end