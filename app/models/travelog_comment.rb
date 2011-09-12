class TravelogComment < ActiveRecord::Base
    
     belongs_to :user, :class_name => "User", :foreign_key => "user_id"
     belongs_to :travelog, :class_name => "Travelog", :foreign_key => "travelog_id"
end
