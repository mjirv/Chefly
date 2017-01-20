# Chefly
This recipe app allows users to randomly select recipes from a database and generate grocery lists based on those recipes. I was tired of spending time looking for recipes and manually turning them into a grocery list every week (adding all the groceries up, seeing what overlapped, etc). So I built a Rails app!

You can use Chefly live at www.chefly.xyz or deploy it for yourself following the instructions here.

## Overview
### Sign-in
Chefly users must be authenticated because it stores recipes and grocery lists on a user-by-user basis. Chefly can also email the grocery list to the user with one click.

### Recipes
Chefly lists each of the user's recipes with the groceries needed to make the recipe plus a link to its instructions.

### Grocery Lists
Chefly automatically combines a user's recipes into a grocery list by finding matching grocery items across recipes (even if they're called something different), combining, and adding them. The user has the full ability to edit their grocery list items, so they can rename the groceries or change quantities as they need!

### Instacart integration
If you're running Chefly locally, there's Chromedriver Python code embedded that can automatically add your groceries to your Instacart. This isn't enabled by default because then any user could start adding items to the server owner's Instacart.

## To deploy:
* Clone onto the production machine
* Run `bundle install`
* Set a production `secret_key_base` environment variable
* Update `config/database.yml` to use your favorite database, configure it appropriately, and start it
* Change the email and password in `lib/tasks/create_user.rake` to something you want to use
* Run `RAILS_ENV=production rake db:schema:load`
* cd to `bin` and run `RAILS_ENV=production rake user:create_user`
* Run `RAILS_ENV=production rake items_to_db:items_to_db["/path/to/basic_foods.txt"]`
* Gunzip `recipeitems-latest.json.gz`
* Run `RAILS_ENV=production rake parse_recipes:recipes_to_db_object["/path/to/recipeitems-latest.json"]`
* Run `RAILS_ENV=production rake remove_bad_recipes:remove_bad_recipes`
* Start the database, for example with `service postgresql start`
* Start the server, for example with `RAILS_ENV=production rails s -p 80`
* Navigate to the running webpage, log in as the admin user you created, and do what you want!

## Acknowledgements
* I use a list of basic food items adapted from Python's NLTK library
* 
