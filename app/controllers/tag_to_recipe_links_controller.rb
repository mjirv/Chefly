class TagToRecipeLinksController < ApplicationController
    # Only admins can use mapping
    before_action -> { authorize_admin }

    def index
        @recipe = params[:recipe_id]
        @user_id = params[:user_id]
        @recipe_name = Recipe.find(@recipe).name
        @tags = TagToRecipeLink.where(:recipe_id => @recipe).map(&:tag).pluck(:id, :name)
        @recipe_tag = TagToRecipeLink.new
    end

    def show
        @recipe_tag = TagToRecipeLink.find(params[:id])
    end

    def create
        # Get 5 random recipes
        # Show their info like regular
        # Allow admin to add tags
        # This should be in UsersController huh

        # Assumes that a recipe ID and tag name are passed in
        @tag = Tag.find_or_create_by(name: params[:tag_name]).id
        @recipe = params[:recipe_id]
        @user = params[:user_id]
        @recipe_tag = TagToRecipeLink.where(:tag_id => @tag, :recipe_id => @recipe).first_or_create.save!
        
        if @recipe_tag
            redirect_to show_recipe_tags_path(recipe_id: @recipe, user_id: @user)
        else
            return false
        end
    end

    def delete
        @tag = params[:tag_id]
        @recipe = params[:recipe_id]
        @user = params[:user_id]

        if TagToRecipeLink.where(:tag_id => @tag, :recipe_id => @recipe).map(&:delete)
            redirect_to show_recipe_tags_path(recipe_id: @recipe, user_id: @user)
        else
            return false
        end
    end
end
