class AddItemAmountToRecipeItem < ActiveRecord::Migration[5.0]
  def change
    add_column :recipe_items, :item_amount, :integer
  end
end
