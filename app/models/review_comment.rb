class ReviewComment < ActiveRecord::Base
  
     belongs_to :user, :class_name => "User", :foreign_key => "user_id"
     belongs_to :review, :class_name => "Review", :foreign_key => "review_id"
     
end
