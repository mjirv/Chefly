require 'mail'
require "net/https"
require "uri"


class GroceryListsController < ApplicationController
    # Make sure the right user is logged in
    before_action -> { authorize_id(GroceryList.find(params[:id]).user_id) rescue authorize_id(params[:user_id]) }
    # Only admin can load the mapping
    before_action -> { authorize_admin }, only: [:item_mapping]


    def show
        @grocery_list = GroceryList.find(params[:id])
        @grocery_list_items = GroceryListItem.where(:grocery_list_id => params[:id]).where.not(:visible => false).includes(:recipe_item)
    end

    def update
        @grocery_list = GroceryList.find(params[:id])
    end

    # Emails the grocery list to the user who owns it
    def email
        @grocery_list = GroceryList.find(params[:id])
        user_id = @grocery_list.user_id
        user_email = User.find(user_id).email
        recipes = Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id))
        message = ""

        # First part of the message lists all the recipes
        recipes.each do |recipe|
            message << 
            "<b>#{recipe.name}</b>
            <br />#{recipe.recipe_items.pluck(:name).join("<br />")}
            <br />#{recipe.url}
            <br /><br />"
        end

        # Second part is the combined grocery list
        message <<
        "<b>Shopping List</b>
        <br />#{@grocery_list.get_list.join("<br />")}"

        puts "Email: #{ENV["FROM_EMAIL"]}"

        # Change this if you want to send emails another way
        options = { :address => 'smtp.gmail.com',
                    :port => 587,
                    :domain => 'gmail.com',
                    :user_name => ENV["FROM_EMAIL"],
                    :password => ENV["FROM_EMAIL_PASSWORD"],
                    :authentication => 'plain',
                    :enable_starttls_auto => true }

        Mail.defaults do
            delivery_method :smtp, options
        end

        Mail.deliver do 
            content_type 'text/html; charset=UTF-8'
            to user_email
            # TODO: This should use an env variable to get the site name
            from  "Michael's Recipe App #{ENV['FROM_EMAIL']}"
            subject "Your recipes for the week are ready!"
            body message
        end

        # TODO: Add an alert that the email sent or failed
        flash.notice = "Successfully sent email"
        redirect_to dashboard_path(user_id)
    end

    def item_mapping
        @grocery_list = GroceryList.find(params[:id])
        @grocery_list_items = GroceryListItem.where(:grocery_list_id => params[:id]).where.not(:visible => false)
    end

    # Used when we update the grocery list and want to immediately call it
    def update_and_show
        grocery_list = GroceryList.find(params[:id])
        user = grocery_list.user_id
        grocery_list.deduplicate()
        grocery_list.regenerate_items()
        redirect_to grocery_list_path(params[:id])
    end

    # The top-level function to change a grocery list from user's active recipes
    def change_grocery_list(user_id = false, redirect_to_gl=false, refresh="false")
        # I don't think I can use params as defaults, thus why these are needed
        if not user_id
            user_id = params[:user_id]
        end

        if not redirect_to_gl
            redirect_to_gl = params[:redirect_to_gl]
        end

        if refresh == "false"
            refresh = params[:refresh] || "false"
        end

        if GroceryList.where(:user_id => user_id).where(:status => GroceryList.statuses["active"]) != []
            # If we're not deleting all previous recipes, just update the grocery list
            if refresh == "false"
                update_grocery_list(user_id, redirect_to_gl)

            # If we are, delete the old one and make a new one
            else
                GroceryList.where(:user_id => user_id).where(:status => [GroceryList.statuses["active"], nil]).map do |g| 
                    g.delete
                end
                generate_new_grocery_list(user_id, redirect_to_gl)  
            end
        end
    end

    # Called by change_grocery_list when we only want to add to the current one
    def update_grocery_list(user_id, redirect_to_gl)
        # We only care about the new recipe
        # Assumption is we're only adding one recipe
        last_recipe_id = RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).last.recipe_id rescue nil
        recipe_items = []
        if last_recipe_id
            recipe_items = RecipeItem.where(:recipe_id => last_recipe_id).includes(:item).includes(:quantity).includes(:quantity => :unit)
        end
        # Assume there is only one active list per user, which there should be
        grocery_list = GroceryList.where(:user_id => user_id).where(:status => GroceryList.statuses["active"]).first

        add_recipe_items_to_list(recipe_items, grocery_list, redirect_to_gl, user_id)
    end

    # Called by change_grocery_list when we want to create a totally new one
    def generate_new_grocery_list(user_id, redirect_to_gl)
        recipe_items = RecipeItem.where(:recipe_id => Recipe.where(:id => RecipeToUserLink.where(:status => RecipeToUserLink.statuses["active"]).where(:user_id => user_id).pluck(:recipe_id))).includes(:item).includes(:quantity).includes(:quantity => :unit)
        
        # Make a new grocery list
        # TODO: Ideally the logic in add_recipe_items_to_list should be handled in the GroceryList initializer
        grocery_list = GroceryList.create(:user_id => user_id, :status => GroceryList.statuses["active"])

        add_recipe_items_to_list(recipe_items, grocery_list, redirect_to_gl, user_id)
    end

    # Creates GroceryListItems from RecipeItems and adds them to a GroceryList
    # Not dependent on whether the GroceryList is new or just updating
    def add_recipe_items_to_list(recipe_items, grocery_list, redirect_to_gl, user_id)
        grocery_list_id = grocery_list.id
        recipe_items.each do |ri|
            item_name = ri.item.name

            # Exclude items that aren't real, such as "For the gravy:"
            if item_name.match(/[a-z]+/) && item_name[-1] != ":"
                unit_name = ri.quantity.unit.name

                # GroceryListItem should be named "unit items"
                gli_name = "#{unit_name} #{item_name}"
                amount = ri.quantity.amount
                recipe_item_id = ri.id

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
        else
            redirect_to show_user_recipes_path(user_id)
        end
    rescue AbstractController::DoubleRenderError
        # The above may be the second redirect
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

    private
    # Not currently used, but you could make your server open your instacart and order things for you
    def add_item_to_instacart(item)
        uri = URI.parse("https://instacart.com/")
    end
end
