class Unit < ApplicationRecord
	has_many :quantities, :dependent => :destroy
end
