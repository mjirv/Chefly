class RecipeToUserLink < ApplicationRecord
	enum status: [ :active, :inactive ]
	belongs_to :recipe
	belongs_to :user
end
