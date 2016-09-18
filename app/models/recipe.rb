class Recipe < ApplicationRecord
	has_many :recipe_items, dependent: :destroy
	has_many :recipe_to_user_links, dependent: :destroy
end
