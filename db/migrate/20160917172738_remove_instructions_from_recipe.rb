class RemoveInstructionsFromRecipe < ActiveRecord::Migration[5.0]
  def change
    remove_column :recipes, :instructions, :text
  end
end
