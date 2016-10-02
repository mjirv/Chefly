class AddStringAmtToQuantity < ActiveRecord::Migration[5.0]
  def change
    add_column :quantities, :string_amt, :string
  end
end
