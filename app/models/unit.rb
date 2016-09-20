class Unit < ApplicationRecord
	validates :name, presence: true
	
	has_many :quantities, :dependent => :destroy
end
