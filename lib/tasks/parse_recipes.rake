require 'json'

namespace :parse_recipes do
  desc "Takes json recipes and puts them into our database!"
  task :recipes_to_db_object, [:recipes_path] => [:environment] do |t, args|
  	# Thanks to Jakob S and Josh Pinter at Stack Overflow
  	# http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
  	def is_number? string
		true if Float(string) rescue false
	end

    # Read the file at filepath one-by-one and send the line to recipe_to_db
  	def get_recipes(filepath)
		n = 0
		File.readlines(filepath).shuffle.each do |line|
            recipe_to_db(JSON.parse(line))
            if n % 1000 == 1
                print "#{n} "
            end
			n += 1
		end
	end

    # Takes in a recipe from the file, creates a Recipe in the database, and calls recipe_items_to_db to make Items in the database
	def recipe_to_db(recipe)
		recipe_items = recipe["ingredients"].split("\n")
		db_recipe = Recipe.create(:name => recipe["name"], :url => recipe["url"])
		recipe_items_to_db(recipe_items, db_recipe.id)

		# We don't want recipes with no items
		if db_recipe.recipe_items == []
			db_recipe.delete
		end
	end

    # Takes in a list of recipe items and parses them into database models
	def recipe_items_to_db(recipe_items, recipe_id)
		recipe_items.each do |recipe_item|
			begin
				words = recipe_item.split(" ")

				# Fraction like 1/4 tablespoon salt
				if words[0].nil?
				elsif words[1].nil?

				elsif words[0].match(/^[1-9]\/[1-9]$/)
                    # Create the Unit
					unit = unit_to_db(words[1].downcase())

                    # Get the amount and create the Quantity
					fraction = words[0].split("/")
					q = Quantity.find_or_create_by(:amount => Float(fraction[0])/Float(fraction[1]), :unit_id => unit)
					q.save

                    # Create the Item and the RecipeItem
					item = item_to_db(words[2..-1].join(" ").downcase())
                    create_recipe_item(recipe_id, item, q.id, recipe_item)


				# Mixed number like 1 1/2 tablespoons salt
				elsif is_number?(words[0]) && words[1].match(/^[1-9]\/[1-9]$/)
                    # Create the Unit
					unit = unit_to_db(words[2].downcase())

                    # Get the amount and create the Quantity
					fraction = words[1].split("/")
					q = Quantity.find_or_create_by(:amount => Float(words[0]) + Float(fraction[0])/Float(fraction[1]), :unit_id => unit)
					q.save

                    # Create the Item and the RecipeItem
					item = item_to_db(words[3..-1].join(" ").downcase())
                    create_recipe_item(recipe_id, item, q.id, recipe_item)

				# Whole number like 1 tablespoon salt
				elsif is_number? words[0]
                    # Create the Unit
					unit = unit_to_db(words[1].downcase())

                    # Get the amount and create the Quantity
					q = Quantity.find_or_create_by(:amount => Float(words[0]), :unit_id => unit)
					q.save

                    # Create the Item and the RecipeItem
					item = item_to_db(words[2..-1].join(" ").downcase())
                    create_recipe_item(recipe_id, item, q.id, recipe_item)


				# Not numeric like pinch of salt
				else
                    # Create the Unit
					unit = unit_to_db("NULL_UNIT")

                    # Create the Quantity with amount 1.0
                    # Should this always be 1.0?
					q = Quantity.find_or_create_by(:amount => 1.0, :unit_id => unit)
					q.save

                    # Create the Item and the RecipeItem
					item = item_to_db(recipe_item)
                    create_recipe_item(recipe_id, item, q.id, recipe_item)
				end
            
            # If there's an error, ignore it and print that it happened
			rescue => e
				print "#{e} item error "
			end
		end


	end

    # Takes in a unit name and creates a Unit in the database or returns the existing one
	def unit_to_db(new_unit)
        # Check all existing Units to see if we have a match
		units = Unit.all
		units.each do |unit|
			if unit.name.include?(new_unit) or new_unit.include?(unit.name)
				return unit.id
			end
		end

		# If we didn't find a matching Unit, create a new one
		new_db_unit = Unit.new(:name => new_unit)
		new_db_unit.save
		return new_db_unit.id
	end

    # Takes in an item name and creates an Item in the database or returns the existing one
	def item_to_db(str)
        # Clean the item name
		str = str.strip.downcase.gsub('"', "")
		if str.include?(",")
			str = str.slice(0..(str.index(',') - 1))
		end
		# Add beginning and trailing spaces so our "full word" check below works on first and last word in name
		str = " " + str + " "

        # Check all the existing Items to see if we have a match
		items = Item.all.pluck(:id, :name)
		
		candidates = []
		items.each do |item_id, item_name|
			# Only get full words/phrases, not subsets of words
			if str.include?(" " + item_name + " ")
				candidates << [item_name.length, item_id]
			end
		end

        # If multiple items, choose the one with the longest name
		item_id = candidates.max[1] rescue nil

        # If no matching item, return nil, because we only want to create new Items in the items_to_db task
		return item_id
	end

    # Takes in an ID, an item ID, a quantity ID, and a recipe name, and makes a RecipeItem in the database
    def create_recipe_item(recipe_id, item, qid, recipe_item)
        ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => qid, :name => recipe_item)
        ri.save
    end

	# Uncomment this if there are already recipes in the DB and you want to overwrite them
	Recipe.all.map(&:delete)
	get_recipes(args.recipes_path)
  end

end
