class Quantity < ApplicationRecord
	validates :unit_id, :amount, presence: true

	belongs_to :unit
end
