class AddItemNameToGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    add_column :grocery_list_items, :item_name, :string
  end
end
