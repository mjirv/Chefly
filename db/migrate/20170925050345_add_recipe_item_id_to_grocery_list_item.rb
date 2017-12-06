class AddRecipeItemIdToGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    add_column :grocery_list_items, :recipe_item_id, :integer
  end
end
