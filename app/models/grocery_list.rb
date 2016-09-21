class GroceryList < ApplicationRecord
	validates :user_id, presence: true
	validates :status, presence: true

	belongs_to :user
	has_many :grocery_list_items
	enum status: [ :active, :inactive ]

	before_create do
		@list = Hash.new(0)
	end

	def add_to_list(name, amount)
		if amount.is_a?(Float)
			@list[name] += amount.to_f
		elsif amount == "" && @list[name] == 0
			@list[name] = ""
		end
	end

	def save_list
		@list.each do |item|
			new_item = GroceryListItem.create(:name => item[0], :amount => item[1], :grocery_list_id => self.id)
		end
	end

	def get_list
		list = []
		self.grocery_list_items.each do |item|
			list << item.to_s
		end
		list
	end
end
