class AddUnitIdToQuantity < ActiveRecord::Migration[5.0]
  def change
    add_column :quantities, :unit_id, :integer
  end
end
