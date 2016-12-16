# README

This recipe app allows users to randomly select recipes from a database and generate grocery lists based on those recipes.

### To deploy:
* Clone onto the production machine
* Run `bundle install`
* Set a production `secret_key_base` environment variable
* Update `config/database.yml` to use your favorite database, configure it appropriately, and start it
* Change the email and password in `lib/tasks/create_user.rake` to something you want to use
* Run `RAILS_ENV=production rake db:schema:load
* cd to `bin` and run `RAILS_ENV=production rake user:create_user`
* Run `RAILS_ENV=production rake items_to_db:items_to_db["/path/to/basic_foods.txt"]`
* Gunzip `recipeitems-latest.json.gz`
* Run `RAILS_ENV=production rake parse_recipes:recipes_to_db_object["/path/to/recipeitems-latest.json"]`
* Start the server, for example with `RAILS_ENV=production rails s -p 80`
* Navigate to the running webpage, log in as the admin user you created, and do what you want!
