class User < ApplicationRecord
    before_validation :default_values

	validates :email, presence: true
	validates :email, uniqueness: true
	validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, message: "Must be a valid email address." }
	validates :google_id, presence: true
	validates :status, presence: true
	validates :permission, presence: true

	has_many :recipe_to_user_links, :dependent => :destroy
	has_many :grocery_lists, :dependent => :destroy
	enum status: [ :active, :inactive ]
    enum permission: [ :user, :admin ]
    
    private
    def default_values
        puts "ran!"
        self.status = 'active' if self.status.nil?
        self.permission = 'user' if self.permission.nil?
    end
end
