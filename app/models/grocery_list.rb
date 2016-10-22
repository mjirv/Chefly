class GroceryList < ApplicationRecord
	validates :user_id, presence: true
	validates :status, presence: true

	belongs_to :user
	has_many :grocery_list_items
	enum status: [ :active, :inactive ]

	before_create do
		@list = Hash.new([0])
	end

	def deduplicate
		units = GroceryListItem.where(:grocery_list_id => self.id).joins(:recipe_item).joins('INNER JOIN quantities on recipe_items.quantity_id = quantities.id').pluck('quantities.unit_id').uniq

		units.each do |unit|
			glis = GroceryListItem.where(:grocery_list_id => self.id).where(:visible => true).where(:recipe_item_id => RecipeItem.where(:quantity_id => Quantity.where(:unit_id => unit).pluck(:id)).pluck(:id))
			items = glis.map(&:recipe_item).pluck(:item_id).uniq
			items.each do |item|
				item_glis = glis.select{ |g| RecipeItem.find(g.recipe_item_id).item_id == item }
				if item_glis.length > 1
					sum = item_glis.map{ |g| g.amount }.reduce(0.0, :+)
					new_gli = GroceryListItem.create(:amount => sum, :string_amount => sum.to_s, :name => item_glis.first.name, :grocery_list_id => self.id, :recipe_item_id => item_glis.first.recipe_item_id, :combined => true)
					item_glis.map{ |i| i.visible = false }
					item_glis.map(&:save)
				end
			end
		end
	end

	def get_list
		list = []
		self.grocery_list_items.each do |item|
			list << item.to_s
		end
		list
	end

	def grocery_list_items
		return GroceryListItem.where(:grocery_list_id => self.id).where.not(:visible => false)
	end

	def regenerate_items
		glis = grocery_list_items
		glis.each do |gli|
			if gli.combined != false && gli.user_edited != true
				gli.regenerate()
			end
		end
	end
end
