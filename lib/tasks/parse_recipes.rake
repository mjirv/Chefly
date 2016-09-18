require 'json'

namespace :parse_recipes do
  desc "Takes json recipes and puts them into our database!"
  task :recipes_to_db_object, [:recipes_path] => [:environment] do |t, args|
  	# Thanks to Jakob S and Josh Pinter at Stack Overflow
  	# http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
  	def is_number? string
		true if Float(string) rescue false
	end

  	def get_recipes(filepath)
	  	# Make sure all \ns are "x;x " first
		file = File.read(filepath).split("\n")
		recipes = []
		file.each do |line|
			recipes << JSON.parse(line)
		end
		return recipes
	end

	def recipes_to_db(recipes)
		recipes.each do |recipe|
			recipe_items = recipe["ingredients"].split("x;x ")
			db_recipe = Recipe.new(:name => recipe["name"], :url => recipe["url"])
			db_recipe.save
			recipe_items_to_db(recipe_items, db_recipe.id)
		end
	end

	def recipe_items_to_db(recipe_items, recipe_id)
		recipe_items.each do |recipe_item|
			words = recipe_item.split(" ")
			if is_number? words[0]
				unit = unit_to_db(words[1].downcase())
				q = Quantity.find_or_create_by(:amount => Float(words[0]), :unit_id => unit)
				q.save
				item = item_to_db(words[2..-1].join(" ").downcase())
				ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => q.id, :name => recipe_item)
				ri.save
			else
				unit = unit_to_db("NULL_UNIT")
				q = Quantity.find_or_create_by(:amount => 1.0, :unit_id => unit)
				q.save
				item = item_to_db(recipe_item)
				ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => q.id, :name => recipe_item)
				ri.save
			end
		end


	end

	def unit_to_db(new_unit)
		units = Unit.all
		units.each do |unit|
			if unit.name.include?(new_unit) or new_unit.include?(unit.name)
				return unit.id
			end
		end
		# else
		new_db_unit = Unit.new(:name => new_unit)
		new_db_unit.save
		return new_db_unit.id
	end

	def item_to_db(str)
		items = Item.all
		items.each do |item|
			if item.name.include?(str) or str.include?(item.name)
				return item.id
			end
		end
		# else
		new_db_item = Item.new(:name => str)
		new_db_item.save
		return new_db_item.id
	end 

	recipes = get_recipes(args.recipes_path)
	recipes_to_db(recipes)
  end

end
