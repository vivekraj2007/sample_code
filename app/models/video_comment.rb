class VideoComment < ActiveRecord::Base
  
     belongs_to :user, :class_name => "User", :foreign_key => "user_id"
     belongs_to :videoset, :class_name => "Videoset", :foreign_key => "videoset_id"
end
