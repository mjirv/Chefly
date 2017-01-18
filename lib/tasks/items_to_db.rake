namespace :items_to_db do
	desc "Takes comma-delimeted items from a text file and creates Items in the db based on them."
    task :items_to_db, [:items_filepath] => [:environment] do |t, args|

        # Take in a filepath and return the items from it as a list
        def get_items(filepath)
            file = File.read(filepath).split(", ")
            items = []
            file.each do |item|
                items << item
            end
            return items
        end

        # Take in a list of items and add them to the database
        def to_db(items)
            items.each do |item|
                if item.length > 2
                    db_item = Item.find_or_create_by(:name => item)
                end
            end
        end

        # Delete the items before running so that you aren't duplicating items. You may have to comment this out if creating items for the first time.
        Item.all.map(&:delete)

        items = get_items(args.items_filepath)
        to_db(items)
    end
end