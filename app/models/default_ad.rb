class DefaultAd < ActiveRecord::Base
  belongs_to :advert, :class_name => "Advertisement", :foreign_key => "advertisement_id"
  belongs_to :adv_list, :class_name => "AdvList",:foreign_key => "advertisement_id"
end
