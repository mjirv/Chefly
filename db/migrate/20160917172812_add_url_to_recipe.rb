class AddUrlToRecipe < ActiveRecord::Migration[5.0]
  def change
    add_column :recipes, :url, :string
  end
end
