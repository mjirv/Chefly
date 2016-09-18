class RecipeItem < ApplicationRecord
	belongs_to :recipe
	belongs_to :item
	belongs_to :quantity
end
