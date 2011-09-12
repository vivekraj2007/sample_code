class UserNetwork < ActiveRecord::Base
  
  belongs_to :user_friend, :class_name => "User", :foreign_key => "friend_id"
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  
  #belongs_to :user, :class_name => "User", :foreign_key => "friend_id"
  
def friend_name
    if self.user_id !=nil
      return self.user.screen_name
   else
      return self.user
    end
end
 
end
