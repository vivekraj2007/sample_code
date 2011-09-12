class PhotoComment < ActiveRecord::Base
  
     belongs_to :user, :class_name => "User", :foreign_key => "user_id"
     belongs_to :photoset, :class_name => "Photoset", :foreign_key => "photoset_id"
  
end
