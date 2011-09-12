class See::MapController < ApplicationController

  before_filter :user_information 
  
  before_filter :left_top_adv,:left_bottom_adv,:right_adv

  layout 'see'
  
def index
      if session[:user_id].blank? 
      layout_map
end
    
     @page_title = "Maps"  
     
     order_at = "updated_at DESC"
     order_on = "updated_on DESC"     
     
      if request.post?        
                if params[:types] == 'Photo Sets'
                      condition = ["title is not null AND description is not null AND lat is not null AND longt is not null AND coverimage_id is not null"]   
                      @map = "Photosets"
                      @page_title = "Map - Photo Sets"  
                      @see_map_photosets = Photoset.find(:all,:select => "id,title, lat,longt,coverimage_id ,description,created_on",:conditions => condition, :order => order_on)
               elsif params[:types] == 'Stories'
                      condition = ["stories.title is not null AND stories.added_images is not null AND stories.lat is not null AND stories.longt is not null AND stories.status = 1"]    
                      @map = "Stories"  
                      @page_title = "Map - Stories"  
                      @see_map_stories   = Story.find(:all, :select => "stories.id,stories.title,stories.lat, stories.longt, photos.id as image_id,photos.image as image, stories.sub_title, stories.created_at",:order => order_at, :joins =>"inner join photos on photos.id = stories.added_images AND #{condition}") 
               end
      else
              condition = ["title is not null AND description is not null AND lat is not null AND longt is not null AND coverimage_id is not null"]   
              @see_map_photosets = Photoset.find(:all,:select => "id,title, lat, longt,coverimage_id ,description,created_on",:conditions => condition, :order => order_on)
              condition = ["stories.title is not null AND stories.added_images is not null AND stories.lat is not null AND stories.longt is not null AND stories.status = 1"]   
              @see_map_stories   = Story.find(:all, :select => "stories.id,stories.title, stories.lat, stories.longt, photos.id as image_id,photos.image as image, stories.sub_title, stories.created_at",:order => order_at, :joins =>"inner join photos on photos.id = stories.added_images AND #{condition}") 
     end   

end
   
   def search
   condition = "title LIKE \"%#{params[:search_text]}%\""
   @photosets = Photoset.find(:all,:conditions => condition)
   #~ @videosets = Videoset.find(:all,:conditions => condition)  ## commented on 12-jan-2009 by sarma
   condition = "title LIKE \"%#{params[:search_text]}%\" AND status = 1"
   @stories   = Story.find(:all,:conditions => condition)
   #~ @reviews = Review.find(:all,:conditions => condition)      ## commented on 12-jan-2009 by sarma
   #~ @travelogs = Travelog.find(:all,:conditions => condition)   ## commented on 12-jan-2009 by sarma
   render :action => "index" 
   end   

end
