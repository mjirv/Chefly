class GroceryListItem < ApplicationRecord
	validates :grocery_list_id, presence: true
	validates :name, presence: true

	belongs_to :grocery_list
	belongs_to :recipe_item

    # Needed to convert the string amount to fractions for display in the GroceryList
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

    # Make sure every GLI has an entry for visible and combined
	before_create do
		self.generate_string_amount
		if self.visible == nil
			self.visible = true
		end
		if self.combined == nil
			self.combined = false
		end
	end

    # Convert the amount to a readable fraction
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

    # Returns the GLI's Item's name
	def get_item_name
		item = Item.find(RecipeItem.find(self.recipe_item_id).item_id)
		return item.name
	end

    # So you can print the GLI
	def to_s
		"#{self.string_amount}#{self.name}"
	end

    # Refreshes the string_amount and name in case anything has changed
	def regenerate
		self.string_amount = to_string_amount(self.recipe_item.quantity.amount)
		self.name = "#{to_unit_name(self.recipe_item.quantity.unit.name)} #{self.recipe_item.item.name}"
		self.save
	end

	private
    # Not totally sure why we need this and generate_string_amount
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

    # Changes the unit name to nothing instead of NULL_UNIT if needed
	def to_unit_name(name)
		if name == "NULL_UNIT"
			name = ""
		end
		return name
	end
end
