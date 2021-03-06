class Item < ApplicationRecord
	validates :name, presence: true
	#validates :name, uniqueness: true

	has_many :recipe_items, :dependent => :destroy
	has_many :tags
	has_many :grocery_list_items
end
