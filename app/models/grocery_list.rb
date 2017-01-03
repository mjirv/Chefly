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
        # Merges multiple grocery list items with the same item ID and unit type
        # Get the list of GLI IDs, item IDs, unit IDs, and GLI names
        glis = get_glis()

        # Loop through each of the glis
        while glis.length != 0
            # "Pop" the first one
            gli = glis.first

            # Pull those with same item ID and unit ID
            mergeable_glis = glis.select{ |candidate| candidate.item_id == gli.item_id && candidate.unit_id == gli.unit_id }

            # Get merged amount
            new_amount = mergeable_glis.map{ |mgli| mgli.amount }.reduce(:+) + gli.amount

            # Add the merged GLI
            new_merged_gli = GroceryListItem.new(:name => gli.name, :amount => new_amount, :grocery_list_id => gli.id, :recipe_item_id => gli.recipe_item_id, :visible => true, :combined => true, :user_edited => false)

            # Make the earlier ones invisible
            mglis_ids = mergeable_glis.map(&:id) + [gli.id]
            GroceryListItem.find(mglis_ids).map do |g|
                g.visible = false
                g.save
            end
            glis = get_glis()
        end
    end

    def get_list
        list = []
        self.grocery_list_items.each do |item|
            list << item.to_s
        end
        list
    end

    def get_glis
        glis = GroceryListItem.where(:grocery_list_id => self.id).where(:visible => [true, nil]).where(:combined => [false, nil]).where(:user_edited => [true, nil]).joins(:recipe_item).joins('INNER JOIN quantities on recipe_items.quantity_id = quantities.id').select('grocery_list_items.id AS id, grocery_list_items.name AS name, quantities.unit_id AS unit_id, grocery_list_items.recipe_item_id AS recipe_item_id, recipe_items.item_id as item_id, grocery_list_items.amount as amount')
        return glis
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
