class AddCombinedToGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    add_column :grocery_list_items, :combined, :boolean
  end
end
