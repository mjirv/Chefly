class AddGoogleIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :google_id, :string
    add_column :users, :name, :string
    remove_column :users, :first_name, :string
    remove_column :users, :last_name, :string
    remove_column :users, :password_digest, :string
  end
end
