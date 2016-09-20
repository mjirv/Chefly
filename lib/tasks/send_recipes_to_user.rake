require 'mail'

namespace :send_recipes do
  desc "Creates five new recipes for a user and deactivates old ones"
  task :get_recipes_for_user, [:user_email] => [:environment] do |t, args|
  	begin
  		user_id = User.where(:email => args.user_email).first.id

	  	# Get rid of last week's recipes
	  	# TODO: separate this part out to its own task when giving user ability to review recipes
	  	last_week_recipes = RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id)
	  	last_week_recipes.map{ |r| r.status = RecipeToUserLink.statuses["inactive"]}
	  	last_week_recipes.map{ |r| r.save }

	  	# Get some new random ones!
	  	recipes = Recipe.limit(5).order("RANDOM()")
	  	recipes.each do |recipe|
	  		link = RecipeToUserLink.new(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe.id)
	  		link.save
	  		puts recipe.recipe_items.pluck(:name)
	  		puts recipe.url
	  		puts ""
  		end
  	rescue
  		puts "Recipe does not exist." #TODO: check that that's actually the error and handle it better
  	end
  end

  desc "Sends a user's active recipes to them"
  task :send_recipes_to_user, [:user_email, :from_email, :from_password] => [:environment] do |t, args|
  	begin
	  	user_id = User.where(:email => args.user_email).first.id

	  	# Temporary. I should refactor this so that sending is done as a method of the GroceryList
	  	if GroceryList.where(:user_id => user_id).where(:status => GroceryList.statuses["active"]) != []
	  		GroceryList.where(:user_id => user_id).map{ |g| g.status = GroceryList.statuses["inactive"] }
	  	end

	  	recipes = Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id))
	  	grocery_list = GroceryList.create(:user_id => user_id, :status => GroceryList.statuses["active"])
	  	message =
	""

	  	recipes.each do |recipe|
	  		recipe.recipe_items.each do |ri|
	  			item_name = ri.item.name
	  			unit_name = ri.quantity.unit.name
	  			list_key = "#{unit_name} #{item_name}"
	  			amount = ri.quantity.amount

	  			if unit_name == "NULL_UNIT"
	  				amount = ""
	  				list_key = "#{item_name}"
	  			end

	  			grocery_list.add_to_list(list_key, amount)

	  		end
	  		message << 
			"<b>#{recipe.name}</b>
			<br />#{recipe.recipe_items.pluck(:name).join("<br />")}
			<br />#{recipe.url}
			<br /><br />"
			grocery_list.save
	  	end
	  	grocery_list.generate_string_list
	  	grocery_list.save

	  	message <<
	"<b>Shopping List</b>
	<br />#{grocery_list.get_string_list.map{ |i| "#{i[1]} #{i[0]}"}.join("<br />")}"
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
	rescue
		puts "User does not exist."
	end
  end
end