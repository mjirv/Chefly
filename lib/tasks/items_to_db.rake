namespace :items_to_db do
	desc "Takes comma-delimeted items from a text file and creates Items in the db based on them."
    task :items_to_db, [:items_filepath] => [:environment] do |t, args|
        def get_items(filepath)
            # Make sure all \ns are "x;x " first
            file = File.read(filepath).split(", ")
            items = []
            file.each do |item|
                items << item
            end
            return items
        end

        def to_db(items)
            items.each do |item|
                if item.length > 2
                    db_item = Item.find_or_create_by(:name => item)
                end
            end
        end

        items = get_items(args.items_filepath)
        to_db(items)
    end
end