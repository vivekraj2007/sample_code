class Video < ActiveRecord::Base
  
  
  
  # relations
  belongs_to :videosets, :class_name => "Videoset", :foreign_key => "videoset_id"  
  has_many :user, :through => :videoset
  
  
 	file_column :videofile 
  
 
  
  #validates_presence_of :title, :caption, :tags,:location
    #validates_format_of :videofile, :with => %r{\.(flv|mp3|swf|avi|mov|wmv|mpg)$}i, :message => "must bee a video of FLV,MP3,SWF,AVI,MOV,WMV,MPG files"
 
 


end
