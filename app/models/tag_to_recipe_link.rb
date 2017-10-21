class TagToRecipeLink < ApplicationRecord
    validates :tag_id, presence: true
    validates :recipe_id, presence: true

    belongs_to :recipe
    belongs_to :tag
end
