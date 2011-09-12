class PhotosetAdv < ActiveRecord::Base
  
     belongs_to :photoset, :class_name => "Photoset", :foreign_key => "photoset_id"
     belongs_to :top_adv, :class_name => "Advertisement", :foreign_key => "topadv_id", :conditions => ["status like ?",1]
     belongs_to :bottom_adv, :class_name => "Advertisement", :foreign_key => "bottomadv_id", :conditions => ["status like ?",1]
     belongs_to :header_adv, :class_name => "Advertisement", :foreign_key => "headeradv_id", :conditions => ["status like ?",1]
     
     belongs_to :photoset_top_adv, :class_name => "AdvList", :foreign_key => "headeradv_id"
     belongs_to :photoset_left_top_adv, :class_name => "AdvList", :foreign_key => "topadv_id"
     belongs_to :photoset_left_bottom_adv, :class_name => "AdvList", :foreign_key => "bottomadv_id"
     belongs_to :photoset_right_adv, :class_name => "AdvList", :foreign_key => "rightadv_id"
     
     
     
end
