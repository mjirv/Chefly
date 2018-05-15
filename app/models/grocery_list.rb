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
        pairs_with_dupes = glis.group_by{|e| [e.item_id, e.unit_id]}.keep_if{|_, e| e.length > 1}
        
        pairs_with_dupes.each do |item_unit, glis|
            new_amount = glis.map{|gli| gli.amount}.sum()
            new_merged_gli = GroceryListItem.create(
                :name => glis[0].name,
                :amount => new_amount,
                :grocery_list_id => self.id,
                :recipe_item_id => glis[0].recipe_item_id,
                :visible => true,
                :combined => true,
                :user_edited => false)
            #if new_merged_gli
                glis.map do |gli|
                    real_gli = GroceryListItem.find(gli.id) 
                    real_gli.visible = false
                    real_gli.save
                end
            #end      
        end
    end

    # Get the current GroceryList as a string
    def get_list
        list = []
        self.grocery_list_items.each do |item|
            list << item.to_s
        end
        list
    end

    # Gets the GroceryList's uncombined, visible, active GLIs
    def get_glis
        glis = GroceryListItem.where(:grocery_list_id => self.id).where(:visible => [true, nil]).where(:user_edited => [false, nil]).joins(:recipe_item).joins('INNER JOIN quantities on recipe_items.quantity_id = quantities.id').select('grocery_list_items.id AS id, grocery_list_items.name AS name, quantities.unit_id AS unit_id, grocery_list_items.recipe_item_id AS recipe_item_id, recipe_items.item_id as item_id, grocery_list_items.amount as amount, grocery_list_items.grocery_list_id')
        return glis
    end

    # Get all visible GroceryListItems for the current GroceryList
    def grocery_list_items
        return GroceryListItem.where(:grocery_list_id => self.id).
            where.not(:visible => false)
    end

    # Calls regenerate on GLIs that are combined and aren't user-edited
    def regenerate_items
        glis = grocery_list_items
        glis.each do |gli|
            if gli.combined != false && gli.user_edited != true
                gli.regenerate()
            end
        end
    end
end
