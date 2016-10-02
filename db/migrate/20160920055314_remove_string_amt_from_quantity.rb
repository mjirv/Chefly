class RemoveStringAmtFromQuantity < ActiveRecord::Migration[5.0]
  def change
    remove_column :quantities, :string_amt, :string
  end
end
