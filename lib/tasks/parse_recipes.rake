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
		n = 0
		File.readlines(filepath).each do |line|
			recipe_to_db(JSON.parse(line))
			print "#{n} "
			n += 1
		end
	end

	def recipe_to_db(recipe)
		recipe_items = recipe["ingredients"].split("\n")
		db_recipe = Recipe.new(:name => recipe["name"], :url => recipe["url"])
		db_recipe.save
		recipe_items_to_db(recipe_items, db_recipe.id)
	end

	def recipe_items_to_db(recipe_items, recipe_id)
		recipe_items.each do |recipe_item|
			begin
				words = recipe_item.split(" ")
				# Fraction like 1/4 tablespoon salt
				if words[0].nil?
				elsif words[1].nil?

				elsif words[0].match(/^[1-9]\/[1-9]$/)
					unit = unit_to_db(words[1].downcase())
					fraction = words[0].split("/")
					q = Quantity.find_or_create_by(:amount => Float(fraction[0])/Float(fraction[1]), :unit_id => unit)
					q.save
					item = item_to_db(words[2..-1].join(" ").downcase())
					ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => q.id, :name => recipe_item)
					ri.save
				# Mixed number like 1 1/2 tablespoons salt
				elsif is_number?(words[0]) && words[1].match(/^[1-9]\/[1-9]$/)
					unit = unit_to_db(words[2].downcase())
					fraction = words[1].split("/")
					q = Quantity.find_or_create_by(:amount => Float(words[0]) + Float(fraction[0])/Float(fraction[1]), :unit_id => unit)
					q.save
					item = item_to_db(words[3..-1].join(" ").downcase())
					ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => q.id, :name => recipe_item)
					ri.save
				# Whole number like 1 tablespoon salt
				elsif is_number? words[0]
					unit = unit_to_db(words[1].downcase())
					q = Quantity.find_or_create_by(:amount => Float(words[0]), :unit_id => unit)
					q.save
					item = item_to_db(words[2..-1].join(" ").downcase())
					ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => q.id, :name => recipe_item)
					ri.save
				# Not numeric like pinch of salt
				else
					unit = unit_to_db("NULL_UNIT")
					q = Quantity.find_or_create_by(:amount => 1.0, :unit_id => unit)
					q.save
					item = item_to_db(recipe_item)
					ri = RecipeItem.new(:recipe_id => recipe_id, :item_id => item, :quantity_id => q.id, :name => recipe_item)
					ri.save
				end
			rescue
				print "item error"
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
		str = str.strip.downcase.gsub('"', "")
		if str.include?(",")
			str = str.slice(0..(str.index(',') - 1))
		end
		# Add beginning and trailing spaces so our "full word" check below works on first and last word in name
		str = " " + str + " "

		items = Item.all.pluck(:id, :name)
		
		candidates = []
		items.each do |item_id, item_name|
			# Only get full words/phrases, not subsets of words
			if str.include?(" " + item_name + " ")
				candidates << [item_name.length, item_id]
			end
		end

		item_id = candidates.max[1] rescue nil

		return item_id
	end

	# Uncomment this if there are already recipes in the DB and you want to overwrite them
	# Recipe.all.map(&:delete)
	get_recipes(args.recipes_path)
  end

end
