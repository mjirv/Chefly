class RemoveUnitFromQuantity < ActiveRecord::Migration[5.0]
  def change
    remove_column :quantities, :unit, :integer
  end
end
