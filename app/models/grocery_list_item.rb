class GroceryListItem < ApplicationRecord
	validates :grocery_list_id, presence: true
	validates :name, presence: true

	belongs_to :grocery_list

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

	def to_s
		"#{self.string_amount}#{self.name}"
	end
end
