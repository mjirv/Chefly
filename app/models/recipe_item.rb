class RecipeItem < ApplicationRecord
	validates :recipe_id, presence: true
	validates :quantity_id, presence: true

	belongs_to :recipe
	belongs_to :item
	belongs_to :quantity
end
