class UserMail < ActiveRecord::Base
  
  belongs_to :to_id, :class_name => "User", :foreign_key => "to_user"
  belongs_to :from_id, :class_name => "User", :foreign_key => "from_user"
  
  	attr_accessor :email_address
end
