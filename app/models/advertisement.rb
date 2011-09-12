class Advertisement < ActiveRecord::Base
  
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "topadv_id", :dependent => :nullify
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "bottomadv_id", :dependent => :nullify
  has_many :story_adv, :class_name => "StoryAdv",:foreign_key => "headeradv_id", :dependent => :nullify
  
  has_many :photoset_adv, :class_name => "PhotosetAdv",:foreign_key => "topadv_id", :dependent => :nullify
  has_many :photoset_adv, :class_name => "PhotosetAdv",:foreign_key => "bottomadv_id", :dependent => :nullify
  has_many :photoset_adv, :class_name => "PhotosetAdv",:foreign_key => "headeradv_id", :dependent => :nullify
  
  has_many :default_adv, :class_name => "DefaultAdv",:foreign_key => "advertisement_id", :dependent => :nullify
  
end
