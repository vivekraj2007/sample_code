class Myworld::MapController < ApplicationController
 
 before_filter :user_profile_info 
 before_filter :left_top_adv,:left_bottom_adv,:right_adv

 layout 'myworld'
  
  
def index
      screenname = params[:id].gsub('_', ' ')
      @user = User.find_by_screen_name(screenname)    
    if @user
         @page_title = "#{@user.screen_name} - Profile Map"
          #condition = ["lat != '' AND longt !=''"]
          order_at = "updated_at DESC"
          order_on = "updated_on DESC"         
          if request.post?        
                if params[:types] == 'Photo Sets'
                        condition = ["title is not null AND description is not null AND lat is not null AND longt is not null AND coverimage_id is not null"]   
                        @map = "Photo Sets"
                        @page_title = "#{@user.screen_name} - Profile Map - Photo Sets"
                        @myworld_photosets = @user.photosets.find(:all,:select => "id,title, lat, longt,coverimage_id ,description,created_on",:conditions => condition, :order => order_on)
                        #@photosets = @user.photosets.find(:all,:conditions => condition, :order => order_on)
                elsif params[:types] == 'Stories'
                        @map = "Stories"  
                        @page_title = "#{@user.screen_name} - Profile Map - Stories"
                        condition = ["stories.title is not null AND stories.added_images is not null AND stories.lat is not null AND stories.longt is not null AND stories.status = 1"]    
                        @myworld_stories   = @user.stories.find(:all, :select => "stories.id,stories.title, stories.lat, stories.longt, photos.id as image_id,photos.image as image, stories.sub_title, stories.created_at",:order => order_at, :joins =>"inner join photos on photos.id = stories.added_images AND #{condition}") 
   
                #~ elsif params[:types] == 'Friends'
                          #~ @map = "Friends"  
                          #~ @page_title = "#{@user.screen_name} - Profile Map - Friends"
                          #~ condition =["user_id LIKE ?",@user.id]
                          #~ friends = UserNetwork.find_by_friend_id(@user.id)

                          #~ @myworld_friends =  @user.friends.find(:all,:condition => condition)
                          #~ render :text => @user.friends.size and return
                         
                 elsif params[:types] == "Where I'm Going"
                          @map = "Where I'm Going" 
                          @page_title = "#{@user.screen_name} - Profile Map - Places he is Going"
				        elsif params[:types] == "Where I've lived"
                          @map = "Where I've lived" 
                          @page_title = "#{@user.screen_name} - Profile Map - Places he lived"
                 elsif params[:types] == "Favorite Places"
                            @map = "Favorite Places"          
                            @page_title = "#{@user.screen_name} - Profile Map - Favorite Places"
                end
          
          else   
               condition = ["title is not null AND description is not null AND lat is not null AND longt is not null AND coverimage_id is not null"]   
               @myworld_photosets = @user.photosets.find(:all,:select => "id,title, lat, longt,coverimage_id ,description,created_on",:conditions => condition, :order => order_on)
               condition = ["stories.title is not null AND stories.added_images is not null AND stories.lat is not null AND stories.longt is not null AND stories.status = 1"]   
              @myworld_stories   = @user.stories.find(:all, :select => "stories.id,stories.title, stories.lat, stories.longt, photos.id as image_id,photos.image as image, stories.sub_title, stories.created_at",:order => order_at, :joins =>"inner join photos on photos.id = stories.added_images AND #{condition}") 
               #@reviews = @user.reviews.find(:all,:conditions => condition, :order => order_on)     
               #@videosets =  @user.videosets.find(:all,:conditions => condition, :order => order_on)   
               #@travelogs = Travelog.find(:all,:conditions => condition, :order => order_at)
              
              
              @photos = Array.new
               for photo in @myworld_photosets
                 if !photo.lat.blank? && !photo.longt.blank?
                 @photos << photo
                 end
              end
	 
	           #~ @videos = Array.new
             #~ for video in @videosets
                 #~ if !video.lat.blank? && !video.longt.blank?
                 #~ @videos << video
                 #~ end
             #~ end
	 
           @story = Array.new
             for story in @myworld_stories
                 if !story.lat.blank? && !story.longt.blank?
                 @story << story
                 end
             end
	 
           #~ @review = Array.new
             #~ for review in @reviews
                 #~ if !review.lat.blank? && !review.longt.blank?
                 #~ @review << review
                 #~ end
               #~ end
       
            #~ @travelog = Array.new
             #~ for travelog in @travelogs
               #~ if !travelog.lat.blank? && !travelog.longt.blank?
               #~ @travelog << travelog
               #~ end
             #~ end   
        end      
    end        
    #~ rescue
    #~ flash[:notice] = 'Some thing went wrong!!'
    #~ render :template => 'shared/error'and return 
end   
  
  #~ public
  
  #~ def myworld_advertisements
   #~ @top_adv = Advertisement.find(1)
   #~ @bottom_adv = Advertisement.find(6)    
 #~ end 
  
  
  
  
  #~ def index
  #~ @photosets = Photoset.find(:all, :conditions => ["user_id LIKE ? and lat != '' AND longt !=''",session[:user_id]])
  #~ @stories = Story.find(:all, :conditions => ["user_id LIKE ? and lat != '' AND longt !=''",session[:user_id]])
  #~ @videosets = Videoset.find(:all, :conditions => ["user_id LIKE ? and lat != '' AND longt !=''",session[:user_id]])
    #~ if params[:types] == 'photosets'
       #~ redirect_to :controller => 'myworld/map',:action => 'photos'
    #~ elsif params[:types] == 'stories'
      #~ redirect_to :controller => 'myworld/map',:action => 'mystories'
    #~ elsif params[:types] == 'videosets'
      #~ redirect_to :controller => 'myworld/map',:action => 'videos'
   #~ end
    #~ @user = User.find_by_id(session[:user_id])
    #~ @profile = Profile.find_by_user_id(@user.id)
  #~ end
 
 
 #~ def photos
   #~ @total = 0
   #~ conditions = ["user_id like ? AND lat != '' AND longt !=''", params[:id]]
   #~ @photosets = Photoset.paginate :page => params[:page], :per_page => 3, :conditions => conditions
   
   #~ for photoset in @user_photsets
        #~ total_photos_in_set = photoset.photos.length
        #~ @total = @total + total_photos_in_set 
    #~ end
  #~ end
  
  
  #~ def mystories
     #~ conditions = ["user_id like ? AND lat != '' AND longt !='' AND status LIKE ?",params[:id],1]
     #~ @stories = Story.paginate :page => params[:page], :per_page => 3, :conditions => conditions
   #~ end
   
   
 #~ def videos
   #~ @total = 0
   #~ conditions = ["user_id like ? AND lat != '' AND longt !=''", session[:user_id]]
   #~ @videosets = Videoset.paginate :page => params[:page], :per_page => 3, :conditions => conditions
   #~ for videoset in @user_videosets
        #~ total_videos_in_set = videoset.videos.length
        #~ @total = @total + total_videos_in_set 
    #~ end
  #~ end

end
