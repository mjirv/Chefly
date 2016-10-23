Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/grocery_lists/:id/', to: 'grocery_lists#show', as: 'grocery_list'
  put '/grocery_lists/:id/', to: 'grocery_lists#update_and_show', as: 'update_and_show_grocery_list'
  get '/grocery_lists/edit/:id/', to: 'grocery_lists#update', as: 'edit_grocery_list'
  get '/grocery_lists/:id/item_mapping', to: 'grocery_lists#item_mapping', as: 'gl_item_mapping'
  post '/grocery_lists/email/:id/', to: 'grocery_lists#email', as: 'email_grocery_list'

  get '/grocery_list_items/edit/:id/', to: 'grocery_list_items#update', as: 'edit_grocery_list_item'
  get '/grocery_list_items/map/:id/', to: 'grocery_list_items#map', as: 'map_grocery_list_item'
  post '/grocery_list_items/map/:id/', to: 'grocery_list_items#map_post', as: 'map_post_grocery_list_item'
  patch '/grocery_list_items/:id/', to: 'grocery_list_items#edit_save', as: 'edit_save_grocery_list_item'
  get '/grocery_list_items/:id/', to: 'grocery_list_items#show', as: 'grocery_list_item'
  delete '/grocery_list_items/:id/', to: 'grocery_list_items#delete', as: 'delete_grocery_list_item'

  get '/users/:id/edit/', to: 'users#update', as: 'edit_users'
  get '/users/:id/recipes/', to: 'users#show_recipes', as: 'show_user_recipes'
  get '/users/:id/', to: 'users#show', as: 'user'
  get '/users/:id/generate_recipes/', to: 'users#config_recipe_generation', as: 'config_recipe_generation'
  post '/users/:id/generate_recipes/', to: 'users#generate_recipes', as: 'generate_recipes'
  post '/users/:id/generate_recipe/', to: 'users#generate_recipe', as: 'get_new_user_recipe'
  get '/users/:id/generate_grocery_list', to: 'users#generate_grocery_list', as: 'generate_grocery_list'
  delete '/users/:user_id/delete_recipe/:recipe_id/', to: 'users#delete_recipe', as: 'delete_user_recipe'
  post '/users/:user_id/delete_and_get_new_recipe/:recipe_id/', to: 'users#delete_and_generate_recipe', as: 'delete_and_get_new_user_recipe'
  post '/users/:user_id/auto_instacart/:grocery_list_id', to: 'users#auto_instacart', as: 'auto_instacart'

  get 'signup', to: 'users#new'
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  resources :users

  get '/dashboard/:id/', to: 'dashboard#show', as: 'dashboard'
end
