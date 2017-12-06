class AddUserEditedToGroceryListItem < ActiveRecord::Migration[5.0]
  def change
    add_column :grocery_list_items, :user_edited, :boolean
  end
end
