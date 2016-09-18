class CreateRecipeToUserLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :recipe_to_user_links do |t|
      t.integer :status
      t.references :user
      t.references :recipe

      t.timestamps
    end
  end
end
