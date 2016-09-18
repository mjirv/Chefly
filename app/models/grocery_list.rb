class GroceryList < ApplicationRecord
	belongs_to :user
	has_many :recipe_items, :dependent => :destroy
	enum status: [ :active, :inactive ]
end
