class GroceryListItemsController < ApplicationController
	def update
		@item = GroceryListItem.find(params[:id])
	end

	def edit_save
		@item = GroceryListItem.find(params[:id])
		item_params[:string_amount] = item_params[:string_amount].strip + " "
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

	private
	def item_params
		@item_params ||= params.require(:grocery_list_item).permit(:name, :string_amount)
	end
end
