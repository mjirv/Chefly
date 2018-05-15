class RecipeToUserLinksController < ApplicationController
    # Shows a user's current recipes
    def show_recipes
        @user = User.find(params[:id])
        @admin = authorize_admin_helper
        @recipes = Recipe.
            where(:id => RecipeToUserLink.where(:user_id => @user.id).
            where(:status => RecipeToUserLink.statuses["active"]).
            pluck(:recipe_id))
    end

    def config_recipe_generation
        @user = User.find(params[:id])
        # Can generate between 1 and 10 recipes at once
        @options = (1..10).to_a
    end

    # Helper method, expects a string of comma-separated tag names
    def get_tags(tags)
        # TODO: should fail gracefully if a tag doesn't exist
        if tags == nil
            return nil
        end
        return Tag.where(:name => tags.split(",")).pluck(:id)
    end

    # Called when the user generates new recipes (i.e. this removes all previous recipes and replaces them with new ones)
    def generate_recipes
        user_id = params[:id]
        n_recipes = params[:Config][:n_recipes]
        # tags param should be an array of IDs, or nil
        tag_ids = get_tags(params[:tags])
        
        # Get rid of the previous recipes
        old_recipes = RecipeToUserLink.where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"])
        old_recipes.map{ |r| r.status = RecipeToUserLink.statuses["inactive"] }
        old_recipes.map{ |r| r.save }

        # Get random new recipes and make sure they weren't the old ones
        recipes = get_recipes(n_recipes, tag_ids)
        recipes.each do |recipe|
            link = RecipeToUserLink.create!(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe)
        end

        # Call grocery list generation and redirect to the recipes rather than to the grocery list
        redirect_to change_grocery_list_path(user_id: user_id, redirect_to_gl: "false", refresh: "true")
    end

    # Adds a single recipe to a user
    def generate_recipe
        user_id = User.find(params[:id]).id
        num_recipes = Recipe.all.count
        tags = get_tags(params[:tags] || nil)
        
        # Make sure we aren't duplicating recipes
        if RecipeToUserLink.where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"]).count == num_recipes
            raise RuntimeError, "No more recipes available"
        end

        # Get a random recipe and make sure it's not one of the user's active recipes already
        active_recipes = RecipeToUserLink.where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"]).select(:recipe_id).pluck(:recipe_id)
        recipe = get_recipes(1, tags, active_recipes)[0]

        link = RecipeToUserLink.create!(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe)
        redirect_to change_grocery_list_path(user_id: user_id, redirect_to_gl: "false")
    end

    # Deletes a single recipe
    def delete_recipe
        delete_recipe_helper(params[:id], params[:recipe_id])
        redirect_to change_grocery_list_path(user_id: params[:id], redirect_to_gl: "false")
    end

    # Deletes a single recipe and generates a new one in its place
    def delete_and_generate_recipe
        delete_recipe_helper(params[:id], params[:recipe_id])
        generate_recipe
    end

    private
    # Actually deletes a recipe for a user and regenerates its grocery list
    def delete_recipe_helper(user_id, recipe_id)
        user_recipe = RecipeToUserLink.where(:recipe_id => recipe_id).where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"])
        if user_recipe == []
            raise ArgumentError, "Recipe does not exist or is already deleted."
        else
            user_recipe = user_recipe.first
            user_recipe.status = RecipeToUserLink.statuses["inactive"]
            user_recipe.save

            # TODO: There should be a function to delete from a GroceryList without creating a totally new one
            #generate_new_grocery_list(user_id, false)
        end
    end

    # Helper method to get recipe IDs
    def get_recipes(n_recipes, tags=nil, active_recipes=nil)
        tags = tags || []
        if tags.length > 0
            return Recipe.joins("INNER JOIN tag_to_recipe_links on recipes.id = tag_to_recipe_links.recipe_id").
                where(:tag_to_recipe_links => {:tag_id => tags}).
                where.not(:id => active_recipes).
                limit(n_recipes).
                order("RANDOM()").
                select('recipes.id').
                pluck(:id)
        else
            return Recipe.where.not(:id => active_recipes).
            limit(n_recipes).order("RANDOM()").pluck(:id)
        end
    end
end
