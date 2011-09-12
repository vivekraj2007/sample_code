class Story < ActiveRecord::Base
  
  acts_as_rateable
     
  has_permalink :title, :permalink  
     
  #relations
 belongs_to :user, :class_name => "User", :foreign_key => "user_id"
 has_many :story_comments,  :dependent => :destroy
 has_many :linksets, :class_name => 'Linkset',  :foreign_key => "source_id", :conditions => "source_type = 'story' ",:dependent => :destroy
 has_one :story_adv, :class_name => "StoryAdv", :foreign_key => "story_id",:dependent => :destroy
 belongs_to :photoset,:class_name => 'Photoset', :foreign_key => "slideshow_id"
 
 has_many :latest_adventures, :foreign_key => "source_id",  :conditions => "source = 'story' ", :dependent => :destroy
 
 attr_accessor :address, :dragged_images
 
 after_save :add_to_latest_list 
 
   #validations  
   validates_presence_of :title,:message => "can't be blank"  
   validates_presence_of :sub_title,:message => "can't be blank"  
   #validates_presence_of :where_is, :message => "can't be blank" 


  def add_to_latest_list
  story = Story.find(self.id)  
  
   if !story.lat.nil? && !story.longt.nil? && story.status == 1
     latest_list = LatestAdventure.add_to_list(story.id,'story',story.user_id)
   else
    delete_from_list = LatestAdventure.delete_from_list(story.id,'story',story.user_id)  
   end    
  
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
 
 
  def dragged_images
        imagelist = Array[]           
     #slide show code
      #~ if !story.slideshow_id.blank? && story.slideshow_id != 0         
           #~ for slideshow_images in story.photoset.photos
           #~ imagelist.push(slideshow_images.id)
           #~ end   
     
    if !self.added_images.blank?
       for imageid  in self.added_images.split(',')
        imagelist.push(imageid) 
       end
     end  
     
     if !imagelist.blank?
         photos = Photo.find(:all, :conditions => ["id in (#{imagelist.join(",")}) and image is not null"])   
         return photos
     else
        return []
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
        address<<self.country.name+", "+self.country.continent       
      end
    address.chomp(", ") 
    
    end
   
        def self.grapimage_tag(content,content_type)       
      fsplitcontent =  content.split(content_type)
     # return  fsplitcontent 
      count = 0  
      ssplitcontent = Array.new 
       for fs in fsplitcontent
           if count != 0
           ssplitcontent <<  fsplitcontent[count].split('/')
           end  
          count = count+1
        end
       return ssplitcontent        
    end 
   
   
   
   
   
   
   
   
        def self.grapcontent_without_images(content,content_type)       
      fsplitcontent =  content.split(content_type)
      count = 0  
      ssplitcontent = Array.new       
       for fs in fsplitcontent
           if count != 0
             mmsplit= Array.new 
            mmsplit <<  fsplitcontent[count].split('" />')
            unless mmsplit[0][1].nil?
            ssplitcontent << mmsplit[0][1]      
           end
           else
           ssplitcontent <<  fsplitcontent[count]  
           end  
          count = count+1
        end
       return ssplitcontent       
     end 
     
       
       def self.grapimage_id(content)
     count = 0
     fplit = Array.new
      for fs in content
        fplit << content[count][0].split('/')
        count = count+1
      end      
      images_id = Array.new
       for imageid in fplit     
         if  !images_id.include?(imageid)
         images_id << imageid
        end   
     end          
     if images_id.size == 0
     return nil    
     else
      return images_id.join(',')   
       end
     end 

end
