# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
 helper :all   
 
 after_filter OutputCompressionFilter  
 include ExceptionNotifiable 
 
 
 # to know when the mongrelserver is going to stuck
     before_filter :set_process_name_from_request
     def set_process_name_from_request
      $0 = request.path[0,16] 
    end   
    after_filter :unset_process_name_from_request
    def unset_process_name_from_request
      $0 = request.path[0,15] + "*"
    end  

 # method to find ads in all the defaults places.
  before_filter :header_adv
  
   
  protect_from_forgery :only => [:create, :update, :destroy]
  


 
 
private
 
 # method to authorize user 
    def authorize_user
      unless User.find_by_id(session[:user_id])
          session[:original_uri] = request.request_uri
          path = request.env['HTTP_REFERER']
          flash[:login_falied] = "Please log in"  
              if path ==nil
               redirect_to :controller => '/account', :action => 'index'
              else
               redirect_to path
             end        
         end  
       end 
       
  # method to authorize admin 
     def authorize_admin
        unless Admin.find_by_id(session[:admin])
          flash[:notice] = "Please log in"
          redirect_to :controller =>"/admin/login", :action => "index"
        end  
    end       
 

 def gotab_locations
   @main_locations = Location.find(:all,:conditions =>["parent_id = 0 AND name not like 'Australia'"])
 end 
       
 def layout_map 
        order_on = "updated_on DESC"        
        condition = ["lat != '' AND longt !=''"] 
        select_photoset = "user_id,lat,longt,continent,country,state,location,permalink"
        @layout_map_photosets = Photoset.find(:all,:conditions => condition, :order => order_on,:limit => 50,:select => select_photoset) 
        
        order_at = "updated_at DESC"
        condition = ["lat != '' AND longt !='' AND status = 1"]
        select_story= "user_id,lat,longt,continent,country,state,location,permalink"
       @layout_map_stories = Story.find(:all,:conditions => condition, :order => order_at,:limit => 50,:select => select_story)     
 end
  
  #method to collect all the information of logged in user.
  def user_information
    if !session[:user_id].blank?   
   @user_profile = User.find(session[:user_id])  
   @user_photsets = @user_profile.photosets.find(:all) 
   #@user_videosets = @user_profile.videosets.find(:all) 
   #@user_reviews = @user_profile.reviews.find(:all) 
   @user_stories = @user_profile.stories.find(:all,:order => 'title ASC')
   @user_stories_published =  @user_profile.stories.find(:all, :conditions => ["status LIKE ?",1],:order => 'title ASC') 
   #@user_reviews_published = @user_profile.reviews.find(:all,:conditions => ["status LIKE ?",1],:order => 'title ASC') 
   conditions = ["(friend_id LIKE ? or user_id LIKE ?) and (accepted_at is not null)",@user_profile.id,@user_profile.id]
   @user_friends = UserNetwork.find(:all,:conditions => conditions)    
   condition =["user_read = 0" ]
   @user_messages = @user_profile.to_mails.find(:all, :conditions => condition)    
   #@user_travelogs = @user_profile.travelogs.find(:all,:conditions => ["status LIKE ?",1],:order => 'title ASC')
   #@user_travelogs_published = @user_profile.travelogs.find(:all,:conditions => ["status LIKE ?",1],:order => 'title ASC')   
   #@user_videoset = Videoset.find(:all, :conditions => ["user_id LIKE ?", session[:user_id]])
  #else
  #flash[:login_falied] = "Please log in"  
  #redirect_to :controller => '/account', :action => 'register'  
 end
 end 
 
 
 #method to collect all the information of the user to show in myworld right tab
def user_profile_info
    if !params[:id].blank?   
      screenname = params[:id].gsub('_', ' ')
    
          if @user_profile = User.find(:first, :conditions =>["screen_name like ? and activated_at is not null",screenname])  
              conditions = ["lat is not null and longt is not null"] 
              order = "updated_on DESC"
              @user_photsets = @user_profile.photosets.find(:all,:conditions => conditions, :order => order) 
            
             conditions = ["lat is not null and longt is not null and status = 1"] 
           
             @user_stories_published  = @user_profile.stories.find(:all, :conditions => conditions,:order => 'title ASC')
          
             conditions = ["(friend_id LIKE ? or user_id LIKE ?) and (accepted_at is not null)",@user_profile.id,@user_profile.id]
            @user_friends = UserNetwork.find(:all,:conditions => conditions)  
            #@user_friends = UserNetwork.paginate :page => params[:page], :per_page => 3,:conditions => conditions 
             
             if !session[:user_id].blank?  
                   condition =["user_read = 0" ]
                   @user_messages = @user_profile.to_mails.find(:all, :conditions => condition)
             end
                                  
         else
             flash[:notice] = 'No profile exists with the scrren name'
             render :template => 'shared/error', :layout => false and return  
         end
   else
        flash[:notice] = 'No profile exists with the scrren name'
       render :template => 'shared/error', :layout => false and return  
   end  
end
 
 
# method to display default ads in all locations
 #~ def advertisements   
    #~ header = DefaultAd.find_by_id(6)
    #~ @header_adv = !header.advertisement_id.blank? ? header.adv_list.script :  nil
    #~ left_top = DefaultAd.find_by_id(7)
    #~ @left_top_adv = !left_top.advertisement_id.blank? ? left_top.adv_list.script :  nil
    #~ left_bottom = DefaultAd.find_by_id(8)
    #~ @left_bottom_adv = !left_bottom.advertisement_id.blank? ? left_bottom.adv_list.script :  nil
     #~ right = DefaultAd.find_by_id(9)
    #~ @right = !right.advertisement_id.blank? ? right.adv_list.script :  nil
  #~ end
  
# methos to find script for header ad   
  def header_adv 
     header = DefaultAd.find_by_id(6)
    @header_adv = !header.advertisement_id.blank? ? header.adv_list.script :  nil  
  end  

# methos to find script for left top ad   
def left_top_adv 
    left_top = DefaultAd.find_by_id(7)
    @left_top_adv = !left_top.advertisement_id.blank? ? left_top.adv_list.script :  nil 
  end  
  
 # methos to find script for left bottom ad   
def left_bottom_adv 
    left_bottom = DefaultAd.find_by_id(8)
    @left_bottom_adv = !left_bottom.advertisement_id.blank? ? left_bottom.adv_list.script :  nil
end  

 # methos to find script for lright ad   
def right_adv 
     right = DefaultAd.find_by_id(9)
    @right = !right.advertisement_id.blank? ? right.adv_list.script :  nil
end  
  
  
end
