class AddGroceryListIdToGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    add_column :grocery_list_items, :grocery_list_id, :integer
  end
end
