namespace :user do
  desc "Creates a test user"
  task :create_user => :environment do
  	User.create(:password => "test", :password_confirmation => "test", :permission => 1, :status => 0, :email => "michael.j.irvine@gmail.com")
  end
end