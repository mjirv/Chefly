namespace :remove_bad_recipes do
    desc "Removes recipes with an item where the item and unit name are the same, for example '1 pound 1 pound'"
    task :remove_bad_recipes => [:environment] do |t|
        # Takes in a Recipe id and deletes it
        def delete_recipe(recipe_id)
            recipe = Recipe.find(recipe_id) rescue nil
            if recipe != nil
                recipe.delete
                puts "Deleted recipe #{recipe.name}"
            end
        end

        RecipeItem.find_each do |recipe_item|
            recipe_name = recipe_item.name

            # Get each half of the recipe name
            first_part = recipe_name.slice(0, recipe_name.length/2 + 1).strip
            second_part = recipe_name.slice(recipe_name.length/2, recipe_name.length).strip

            if first_part == second_part
                delete_recipe(recipe_item.recipe_id)
            end
        end
    end
end