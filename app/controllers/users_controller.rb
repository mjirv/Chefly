class UsersController < ApplicationController
    # Makes sure the right user is logged in
    before_filter -> { authorize_id(params[:id]) }, except: [:new, :create]
    autocomplete :tag, :name

    def new
        @user = User.new
    end
  
    def create
        @user = User.new(user_params)
        @user.status = User.statuses["active"]
        # What if we want to create an admin? Right now, we have to use the rails console
        @user.permission = User.permissions["user"]
        if @user.save
            session[:user_id] = @user.id
            redirect_to dashboard_path(@user.id)
        else
            flash.alert = "An error occurred."
            redirect_to '/signup'
        end
    end

    def show
        @user = User.find(params[:id])
    end

    def update
        @user = User.find(params[:id])
    end

    # The edit profile form calls this
    def edit_save
        @user = User.find(params[:id])
        if @user.authenticate(user_params[:password]) && @user.update(user_params)
            flash.notice = 'Successfully updated your profile.'
        else
            flash.notice = 'Something went wrong.'
        end
        redirect_to edit_user_path(@user.id)
    end

    # Shows a user's current recipes
    def show_recipes
        @user = User.find(params[:id])
        @recipes = Recipe.where(:id => RecipeToUserLink.where(:user_id => @user.id).where(:status => RecipeToUserLink.statuses["active"]).pluck(:recipe_id))
    end

    def config_recipe_generation
        @user = User.find(params[:id])
        # Can generate between 1 and 10 recipes at once
        @options = (1..10).to_a
    end

    # Helper method, expects a string of comma-separated tag names
    def get_tags(tags)
        # TODO should fail gracefully if a tag doesn't exist
        if tags == nil
            return nil
        end
        return Tag.where(:name => tags.split(", ")).pluck(:id)
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

        # Get random new recipes
        recipes = get_recipes(n_recipes, tag_ids)
        recipes.each do |recipe|
            link = RecipeToUserLink.create!(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe)
        end

        # Call grocery list generation and redirect to the recipes rather than to the grocery list
        change_grocery_list(user_id, "no_redirect", refresh=true)
        redirect_to show_user_recipes_path(:id => user_id), :method => :get
    end

    def get_recipes(n_recipes, tags=nil)
        recipes = tags.length > 0 ? Recipe.joins("INNER JOIN tag_to_recipe_links on recipes.id = tag_to_recipe_links.recipe_id").where(:tag_to_recipe_links => {:tag_id => tags}).limit(n_recipes).order("RANDOM()").pluck(:id) : Recipe.limit(n_recipes).order("RANDOM()").pluck(:id)
        return recipes
    end

    # The top-level function to change a grocery list from user's active recipes
    def change_grocery_list(user_id = false, redirect_to_gl=false, refresh=false)
        # I don't think I can use params as defaults, thus why these are needed
        if not user_id
            user_id = params[:id]
        end

        if not redirect_to_gl
            redirect_to_gl = params[:redirect_to_gl]
        end

        if GroceryList.where(:user_id => user_id).where(:status => GroceryList.statuses["active"]) != []
            # If we're not deleting all previous recipes, just update the grocery list
            if refresh == false
                update_grocery_list(user_id, redirect_to_gl)

            # If we are, delete the old one and make a new one
            else
                GroceryList.where(:user_id => user_id).where(:status => [GroceryList.statuses["active"], nil]).map do |g| 
                    g.status = GroceryList.statuses["inactive"]
                    g.save
                end
            end
        end
        generate_new_grocery_list(user_id, redirect_to_gl)
    end

    # Called by change_grocery_list when we only want to add to the current one
    def update_grocery_list(user_id, redirect_to_gl)
        # We only care about the new recipe
        # Assumption is we're only adding one recipe
        last_recipe_id = RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).last.recipe_id rescue nil
        recipe_items = []
        if last_recipe_id
            recipe_items = RecipeItem.where(:recipe_id => last_recipe_id)
        end
        # Assume there is only one active list per user, which there should be
        grocery_list = GroceryList.where(:user_id => user_id).where(:status => GroceryList.statuses["active"]).first

        add_recipe_items_to_list(recipe_items, grocery_list, redirect_to_gl)
    end

    # Called by change_grocery_list when we want to create a totally new one
    def generate_new_grocery_list(user_id, redirect_to_gl)
        recipe_items = RecipeItem.where(:recipe_id => Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id)))
        
        # Make a new grocery list
        # TODO: Ideally the logic in add_recipe_items_to_list should be handled in the GroceryList initializer
        grocery_list = GroceryList.create(:user_id => user_id, :status => GroceryList.statuses["active"])

        add_recipe_items_to_list(recipe_items, grocery_list, redirect_to_gl)
    end

    # Creates GroceryListItems from RecipeItems and adds them to a GroceryList
    # Not dependent on whether the GroceryList is new or just updating
    def add_recipe_items_to_list(recipe_items, grocery_list, redirect_to_gl)
          recipe_items.each do |ri|
              item_name = ri.item.name

              # Exclude items that aren't real, such as "For the gravy:"
              if item_name.match(/[a-z]+/) && item_name[-1] != ":"
                  unit_name = ri.quantity.unit.name

                  # GroceryListItem should be named "unit items"
                  gli_name = "#{unit_name} #{item_name}"
                  amount = ri.quantity.amount
                  recipe_item_id = ri.id
                  grocery_list_id = grocery_list.id

                  # If no unit, the name should just be "items"
                  if unit_name == "NULL_UNIT"
                      # TODO: Not convinced the amount should be 1.0 here in all cases. What if I want 2 potatoes?
                      amount = 1.0
                      gli_name = "#{item_name}"
                  end

                  string_amount = amount.to_s

                  GroceryListItem.create(:name => gli_name, :amount => amount, :string_amount => string_amount, :recipe_item_id => recipe_item_id, :grocery_list_id => grocery_list_id)
              end
          end
          grocery_list.deduplicate

          if redirect_to_gl == "true"
              redirect_to grocery_list_path(grocery_list.id)
          end
    end

    # Adds a single recipe to a user
    def generate_recipe
        user_id = User.find(params[:id]).id
        num_recipes = Recipe.all.count
        recipe_ids = Recipe.all.pluck(:id)
        tags = get_tags(params[:tags] || nil)
        
        # Make sure we aren't duplicating recipes
        if RecipeToUserLink.where(:user_id => user_id).where(:status => RecipeToUserLink.statuses["active"]).count == num_recipes
            raise RuntimeError, "No more recipes available"
        end

        # Get a random recipe
        recipe = get_recipes(1, tags)[0]
        # Make sure it wasn't already one of the user's active recipes
        while RecipeToUserLink.where(:user_id => user_id).where(:recipe_id => recipe).where(:status => RecipeToUserLink.statuses["active"]) != []
            recipe = get_recipes(1, tags)[0]
        end

        link = RecipeToUserLink.create(:status => RecipeToUserLink.statuses["active"], :user_id => user_id, :recipe_id => recipe)
        change_grocery_list(user_id)
        redirect_to show_user_recipes_path(user_id)
    end

    # Deletes a single recipe
    def delete_recipe
        delete_recipe_helper(params[:id], params[:recipe_id])
        change_grocery_list(params[:id])
        redirect_to show_user_recipes_path(params[:id])
    end

    # Deletes a single recipe and generates a new one in its place
    def delete_and_generate_recipe
        delete_recipe_helper(params[:id], params[:recipe_id])
        generate_recipe
    end

    # Can order groceries from your grocery list for you by running Instacart via Chromedriver
    def auto_instacart
        # Merge items by adding them to a hash
        item_hash = Hash.new(0)
        grocery_list = GroceryList.find(params[:grocery_list_id].to_i)
        grocery_list.grocery_list_items.each do |item|
            item_hash[item.recipe_item.item.name] += item.recipe_item.item_amount.ceil
        end

        item_hash_str = item_hash.to_s.gsub("\"", "'").gsub("=>", ":")
        
        # TODO: Remove this if not debugging
        print item_hash_str

        instacart_joiner_path = Rails.root.joins('lib', 'utilities', 'instacart_driver.py').to_s

        # TODO: Remove this if not debugging
        print instacart_joiner_path

        # Call the python script that runs Chromedriver
        `python "#{instacart_joiner_path}" #{ENV["INSTACART_USER"]} #{ENV["INSTACART_PASS"]} "#{item_hash_str}" "#{ENV["CHROMEDRIVER_PATH"]}"`
        redirect_to dashboard_path(params[:id])
    end

    def change_password
        @user = User.find(params[:id])
    end

    # Called by submitting change password form
    def change_password_save
        @user = User.find(params[:id])
        # Make sure the user confirmed the new password and entered the correct previous one
        if user_params[:new_password] == user_params[:password_confirmation] && @user.authenticate(user_params[:password]) && @user.update(:password => user_params[:new_password])
            flash.notice = 'Successfully updated your password.'
            redirect_to edit_users_path(@user.id)
        else
            flash.notice = 'You did not provide the right current password, or the new password you entered does not match the confirmation.'
            redirect_to change_password_path(@user.id)
        end
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

    # Get the params in a secure way
    def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :status, :permission, :password_confirmation, :new_password)
    end

end
