class CreateGroceryLists < ActiveRecord::Migration[5.0]
  def change
    create_table :grocery_lists do |t|
      t.integer :status
      t.references :user

      t.timestamps
    end
  end
end
