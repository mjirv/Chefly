class CreateGroceryListItems < ActiveRecord::Migration[5.0]
  def change
    create_table :grocery_list_items do |t|
      t.string :name
      t.float :amount
      t.string :string_amount

      t.timestamps
    end
  end
end
