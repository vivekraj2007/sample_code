class AdvList < ActiveRecord::Base
  
  has_many :default_adv, :class_name => "DefaultAd",:foreign_key => "advertisement_id", :dependent => :nullify
  
 # story adv list 
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "topadv_id", :dependent => :nullify
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "bottomadv_id", :dependent => :nullify
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "headeradv_id", :dependent => :nullify
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "rightadv_id", :dependent => :nullify
  
    
 # photoset adv list 
  has_many :photoset_adv_header, :class_name => "PhotosetAdv",:foreign_key => "headeradv_id", :dependent => :nullify
  has_many :photoset_adv_top, :class_name => "PhotosetAdv",:foreign_key => "topadv_id", :dependent => :nullify
  has_many :photoset_adv_bottom, :class_name => "PhotosetAdv",:foreign_key => "bottomadv_id", :dependent => :nullify
  has_many :photoset_adv_right, :class_name => "PhotosetAdv",:foreign_key => "rightadv_id", :dependent => :nullify
  
  
end
