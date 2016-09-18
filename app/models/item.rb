class Item < ApplicationRecord
	has_many :recipe_items, :dependent => :destroy
	has_many :tags
end
