class GroceryListItemsController < ApplicationController
	before_filter -> { authorize_id(GroceryListItem.find(params[:id]).grocery_list.user_id) }
    before_filter -> { authorize_admin }, only: [:map, :map_post]

	def update
		@item = GroceryListItem.find(params[:id])
	end

	def edit_save
		@item = GroceryListItem.find(params[:id])
		item_params[:string_amount] = item_params[:string_amount].strip + " "
		item_params[:user_edited] = "true"
		if @item.update_attributes(item_params)
			redirect_to edit_grocery_list_path(@item.grocery_list_id)
		end
	end

	def delete
		@item = GroceryListItem.find(params[:id])
		list = @item.grocery_list_id
		if @item.delete
			redirect_to edit_grocery_list_path(list)
		end
	end

	def map
		@gli = GroceryListItem.find(params[:id])
		@recipe_item = @gli.recipe_item
		@item_name = @recipe_item.item.name
	end

	def map_post
		gli = GroceryListItem.find(params[:id])
		recipe_item = gli.recipe_item
		item_amount = params[:item_amount]
		unit_name = params[:unit_name]
		if unit_name == ""
			unit_name = "NULL_UNIT"
		end

		recipe_item.item_amount = params[:item_amount].to_i
		recipe_item.item = Item.find_or_create_by(:name => params[:item_name])
		recipe_item.quantity = Quantity.find_or_create_by(:amount => recipe_item.quantity.amount, :unit_id => Unit.find_or_create_by(:name => unit_name).id)
		if recipe_item.save
			gli.grocery_list.deduplicate
			redirect_to gl_item_mapping_path(gli.grocery_list_id)
		end
	end

	private
	def item_params
		@item_params ||= params.require(:grocery_list_item).permit(:name, :string_amount)
	end
end
