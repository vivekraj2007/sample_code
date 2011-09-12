class Photoset < ActiveRecord::Base
  
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  
  has_many :photos, :dependent => :delete_all  
  has_many :photo_comments, :order => "created_at DESC", :dependent => :delete_all
  
  belongs_to :coverimage, :class_name => "Photo", :foreign_key => "coverimage_id"
  
  has_many :linksets, :class_name => 'Linkset',  :foreign_key => "source_id", :conditions => "source_type = 'photoset' ",:dependent => :delete_all
  
  has_many :linkset_type, :class_name => 'Linkset',  :foreign_key => "link_id", :conditions => "link_type = 'p' ",:dependent => :delete_all
  
  has_many :latest_adventures, :foreign_key => "source_id",  :conditions => "source = 'photoset' ", :dependent => :delete_all
  
   has_many :blanktitle_photos, :class_name => "Photo", :conditions => ['title = "" OR caption = "" OR tags = ""']
   has_many :limited_photos, :class_name => "Photo", :limit => 9, :order => "created_on DESC"
   
   has_one :photoset_adv, :class_name => "PhotosetAdv", :foreign_key => "photoset_id",:dependent => :destroy
  
   has_permalink :title, :permalink  
   
   attr_accessor :address
 
   after_save :add_to_latest_list 
   
  #validations
  validates_presence_of :title, :description
  #~ validates_uniqueness_of :title
  
  def add_to_latest_list
  photoset = Photoset.find(self.id)    
   if !photoset.lat.nil? && !photoset.longt.nil?
     latest_list = LatestAdventure.add_to_list(photoset.id,'photoset',photoset.user_id)
   else
    delete_from_list = LatestAdventure.delete_from_list(photoset.id,'photoset',photoset.user_id)  
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
  

  # method to delete photoset photos added in the stories, reviews, travelogs
  def self.forced_delete(photoset)
      photos = photoset.photos.find(:all)      
      
          for story in photoset.user.stories
             if story.slideshow_id == photoset.id
               story.update_attributes(:slideshow_id => nil)
             end   
              if !story.added_images.blank?
                 for photo in photos           
                   if story.added_images.include?("#{photo.id}")
                  story.update_attributes(:added_images => story.added_images.delete("#{photo.id}"))
                   end
                  end
            end   
          end  


        for review in photoset.user.reviews
             if review.slideshow_id == photoset.id
               review.update_attributes(:slideshow_id => nil)
            end  
              if !review.added_images.blank?
                 for photo in photos           
                   if review.added_images.include?("#{photo.id}")
                  review.update_attributes(:added_images => review.added_images.delete("#{photo.id}"))
                   end
                  end
            end   
          end

        for travelog in photoset.user.travelogs
              if travelog.slideshow_id == photoset.id
               travelog.update_attributes(:slideshow_id => nil)
            end  
              if !travelog.added_images.blank?
                 for photo in photos           
                   if travelog.added_images.include?("#{photo.id}")
                  travelog.update_attributes(:added_images => travelog.added_images.delete("#{photo.id}"))
                   end
                  end
            end   
          end


 end
  
end
