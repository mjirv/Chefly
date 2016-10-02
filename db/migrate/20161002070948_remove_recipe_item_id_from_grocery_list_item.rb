class RemoveRecipeItemIdFromGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    remove_column :grocery_list_items, :recipe_item_id, :integer
  end
end
