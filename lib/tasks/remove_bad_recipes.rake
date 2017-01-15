namespace :remove_bad_recipes do
    desc "Removes recipes with an item where the item and unit name are the same, for example '1 pound 1 pound'"
    task :remove_bad_recipes do
        RecipeItem.each do |recipe_item|
            recipe_name = recipe_item.name
            first_part = recipe_name.slice(0, stringy.length/2 + 1).strip
            second_part = recipe_name.slice(stringy.length/2, stringy.length).strip
            if first_part == second_part
                recipe = Recipe.find(recipe_item.recipe_id)
                recipe.delete
            end
        end
    end
end