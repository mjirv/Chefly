class TagToItemLink < ApplicationRecord
    validates :tag_id, presence: true
    validates :item_id, presence: true

    belongs_to :tag
    belongs_to :item
end
