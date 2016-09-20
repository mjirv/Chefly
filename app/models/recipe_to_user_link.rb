class RecipeToUserLink < ApplicationRecord
	validates :status, presence: true
	validates :recipe_id, presence: true
	validates :user_id, presence: true

	enum status: [ :active, :inactive ]
	belongs_to :recipe
	belongs_to :user
end
