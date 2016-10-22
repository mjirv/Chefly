class GroceryListItem < ApplicationRecord
	validates :grocery_list_id, presence: true
	validates :name, presence: true

	belongs_to :grocery_list
	belongs_to :recipe_item

	FRACTION = {
		"0"  => "",
		"00" => "",
		"13" => "1/8 ",
		"25" => "1/4 ",
		"33" => "1/3 ",
		"50" => "1/2 ",
		"5"  => "1/2 ",
		"67" => "2/3 ",
		"75" => "3/4 "
	}

	before_create do
		self.generate_string_amount
		if self.visible == nil
			self.visible = true
		end
		if self.combined == nil
			self.combined = false
		end
	end

	def generate_string_amount
		if self.amount
			whole, decimal = self.amount.round(2).to_s.split(".")
			if whole == "0"
				self.string_amount = FRACTION[decimal].nil? ? "#{whole}.#{decimal} " : "#{FRACTION[decimal]}"
			else
				self.string_amount = FRACTION[decimal].nil? ? "#{whole}.#{decimal} " : "#{whole} #{FRACTION[decimal]}"
			end
		else
			self.string_amount = ""
		end
	end

	def get_item_name
		item = Item.find(RecipeItem.find(self.recipe_item_id).item_id)
		return item.name
	end

	def to_s
		"#{self.string_amount}#{self.name}"
	end

	def regenerate
		self.string_amount = to_string_amount(self.recipe_item.quantity.amount)
		self.name = "#{to_unit_name(self.recipe_item.quantity.unit.name)} #{self.recipe_item.item.name}"
		self.save
	end

	private
	def to_string_amount(amount)
		string_amount = ""
		if amount
			whole, decimal = amount.round(2).to_s.split(".")
			if whole == "0"
				string_amount = FRACTION[decimal].nil? ? "#{whole}.#{decimal} " : "#{FRACTION[decimal]}"
			else
				string_amount = FRACTION[decimal].nil? ? "#{whole}.#{decimal} " : "#{whole} #{FRACTION[decimal]}"
			end
		end
		return string_amount
	end

	def to_unit_name(name)
		if name == "NULL_UNIT"
			name = ""
		end
		return name
	end
end
