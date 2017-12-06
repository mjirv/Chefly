class AddVisibleToGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    add_column :grocery_list_items, :visible, :boolean
  end
end
