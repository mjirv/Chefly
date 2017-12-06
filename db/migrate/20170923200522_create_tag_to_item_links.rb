class CreateTagToItemLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :tag_to_item_links do |t|
      t.integer :tag_id
      t.integer :item_id

      t.timestamps
    end
  end
end
