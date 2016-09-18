require 'mail'

namespace :send_recipes do
  desc "Creates five new recipes for a user and deactivates old ones"
  task :get_recipes_for_user, [:user_email] => [:environment] do |t, args|
  	user_id = User.where(:email => args.user_email).first.id

  	# Get rid of last week's recipes
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
  end

  desc "Sends a user's active recipes to them"
  task :send_recipes_to_user, [:user_email, :from_email, :from_password] => [:environment] do |t, args|
  	user_id = User.where(:email => args.user_email).first.id
  	recipes = Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id))
  	shopping_list = Hash.new(0)
  	message =
""

  	recipes.each do |recipe|
  		recipe.recipe_items.each do |ri|
  			item_name = ri.item.name
  			unit_name = ri.quantity.unit.name
  			amount = ri.quantity.amount

  			if unit_name == "NULL_UNIT"
  				shopping_list[item_name] += amount
  			else
  				shopping_list["#{unit_name} #{item_name}"] += amount
  			end
  		end
  		message << 
		"<b>#{recipe.name}</b>
		<br />#{recipe.recipe_items.pluck(:name).join("<br />")}
		<br />#{recipe.url}
		<br /><br />"
  	end
  	message <<
"<b>Shopping List</b>
<br />#{shopping_list.map{ |i| "#{i[1]} #{i[0]}"}.join("<br />")}"
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
  end
end