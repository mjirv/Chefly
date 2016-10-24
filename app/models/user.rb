class User < ApplicationRecord
	validates :email, presence: true
	validates :email, uniqueness: true
	validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, message: "Must be a valid email address." }
	validates :password, presence: true
	validates :status, presence: true
	validates :permission, presence: true

	has_many :recipe_to_user_links, :dependent => :destroy
	has_many :grocery_lists, :dependent => :destroy
	enum status: [ :active, :inactive ]
	enum permission: [ :user, :admin ]
	has_secure_password

	validates_confirmation_of :password
end
