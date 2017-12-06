class AddMappedToRecipeItem < ActiveRecord::Migration[5.0]
  def change
    add_column :recipe_items, :mapped, :boolean
  end
end
