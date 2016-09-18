class AddQuantityIdToRecipeItem < ActiveRecord::Migration[5.0]
  def change
    add_column :recipe_items, :quantity_id, :integer
  end
end
