class CreateTagToRecipeLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :tag_to_recipe_links do |t|
      t.integer :tag_id
      t.integer :recipe_id

      t.timestamps
    end
  end
end
