class Location < ActiveRecord::Base  
  
  belongs_to :user
  has_many :sub1, :class_name => "Location", :foreign_key => "parent_id",:limit => 15
  
file_column :image, :magick => {
   :versions => {:thumbnail => "14x14!"}  
  }
  
end
