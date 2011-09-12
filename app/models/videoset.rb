class Videoset < ActiveRecord::Base
  
  #relations
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  
  belongs_to :covervideo, :class_name => "Video", :foreign_key => "covervideo_id"
  has_many :videos,  :dependent => :delete_all
  has_many :linksets, :class_name => 'Linkset',  :foreign_key => "source_id", :conditions => "source_type = 'videoset' ",:dependent => :delete_all
  has_many :linkset_type, :class_name => 'Linkset',  :foreign_key => "link_id", :conditions => "link_type = 'v' ",:dependent => :delete_all
  
  has_many :video_comments, :order => "created_at DESC", :dependent => :delete_all
  
  #latest videos for videoset with updated videos with order by date and limit 9
  has_many :limited_videos, :class_name => "Video", :limit => 9, :order => "created_on DESC"

  has_many :blanktitle_videos, :class_name => "Video", :conditions => ['title = "" OR caption = "" OR tags = ""']

  has_permalink :title, :permalink  
    
  #validations  
   validates_presence_of :title,:message => "can't be blank"  
   validates_presence_of :description,:message => "can't be blank"  
  
   attr_accessor :address
  
  def sliced_title    
    unless self.title==nil
   if self.title.size > 20 || self.title.size == 20
     title= self.title.slice(0,17)+"..."
     return title
   else
     return self.title
  end
  end   
 end
  
  def address
      address=""
      if !self.location.blank?
        address<<self.location
        address<<", "
      end
      if !self.state.blank?        
        address<<self.state
        address<<", "
      end
    if !self.country.blank?        
        address<<self.country
        address<<", "
      end 
    if !self.continent.blank?        
        address<<self.continent
        address<<", "
      end  
    address.chomp(", ")     
    end
   
 # method to delete videoset videos added in the stories, reviews, travelogs
  def self.forced_delete(videoset)
      videos = videoset.videos.find(:all)      
      
        for story in videoset.user.stories
            if !story.added_videos.blank?
               for video in videos           
                 if story.added_videos.include?("#{video.id}")
                story.update_attributes(:added_videos => story.added_videos.delete("#{video.id}"))
                 end
                end
          end   
        end 


      for review in videoset.user.reviews
            if !review.added_videos.blank?
               for video in videos           
                 if review.added_videos.include?("#{video.id}")
                review.update_attributes(:added_videos => review.added_videos.delete("#{video.id}"))
                 end
                end
          end   
        end
        

         for travelog in videoset.user.travelogs
            if !travelog.added_videos.blank?
               for video in videos           
                 if travelog.added_videos.include?("#{video.id}")
                travelog.update_attributes(:added_videos => travelog.added_videos.delete("#{video.id}"))
                 end
                end
          end   
        end
        
 end   
   
   
end
