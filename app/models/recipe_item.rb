class RecipeItem < ApplicationRecord
	validates :recipe_id, presence: true
	validates :quantity_id, presence: true

	belongs_to :recipe
	belongs_to :item
	belongs_to :quantity

    # Makes sure the item_amount is right
    before_create do
        if self.quantity.unit.name == "NULL_UNIT"
            self.item_amount = self.quantity.amount.ceil.to_i
        else
            self.item_amount = 1
        end
    end
end
