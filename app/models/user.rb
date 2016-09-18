class User < ApplicationRecord
	has_many :recipe_to_user_links, :dependent => :destroy
	has_many :grocery_lists, :dependent => :destroy
	enum status: [ :active, :inactive ]
	enum permission: [ :user, :admin ]
	has_secure_password
end
