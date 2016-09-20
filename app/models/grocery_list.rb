class GroceryList < ApplicationRecord
	validates :user_id, presence: true
	validates :status, presence: true

	belongs_to :user
	enum status: [ :active, :inactive ]

	FRACTION = {
		"0"  => "",
		"00" => "",
		"25" => " 1/4",
		"33" => " 1/3",
		"50" => " 1/2",
		"5"  => " 1/2",
		"67" => " 2/3",
		"75" => " 3/4"
	}

	before_create do 
		@list = Hash.new(0)
		@string_list = Hash.new()
	end

	def generate_string_list
		@list.each do |item|
			if item[1] == ""
				@string_list[item[0]] = ""
			else
				whole, decimal = item[1].round(2).to_s.split(".")
				@string_list[item[0]] = FRACTION[decimal].nil? ? "#{whole}.#{decimal}" : "#{whole}#{FRACTION[decimal]}"
			end
		end
		return @string_list
	end

	def add_to_list(name, amount)
		if amount.is_a?(Float)
			@list[name] += amount.to_f
		elsif amount == "" && @list[name] == 0
			@list[name] = ""
		end
	end

	def get_string_list
		return @string_list
	end
end
