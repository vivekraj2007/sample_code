class Myworld::VideosController < ApplicationController
  before_filter :authorize_user, :only => [:comments, :save_comment,:delete_comment]
  before_filter :user_profile_info, :only => [:index]
  before_filter :user_profile_info_with_link, :only =>[:preview,:comments,:save_comment]
   layout 'myworld'
 
  def index     
       conditions = ["lat is not null and longt is not null"]
       @videosets = @user_profile.videosets.paginate :page => params[:page], :per_page => 45, :conditions => conditions, :order => 'created_on DESC'
       @total = @user_profile.videosets.find(:all, :conditions => conditions,:select => "id") 
  end
     
     
     
  def preview     
     conditions = ["lat is not null and longt is not null"] 
     @videosets = @user_profile.videosets.paginate :page => params[:page], :per_page => 25, :conditions => conditions, :order => 'created_on DESC'
     @total = @user_profile.videosets.find(:all, :conditions => conditions, :select => "id")   
     @videoset = Videoset.find(:first,:conditions => ["permalink LIKE ?",params[:id]])
    rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
end



 def video
        @video = Video.find(params[:id])
        @user_videosets = Videoset.find(:all, :conditions => ["user_id like ?", @video.videosets.user_id])
        render :layout=> false 
 end
 
 
 
 # method to display the list of all comments to the videosets
  
  def comments
    @user = User.find(session[:user_id],:select => ["id, screen_name, email"])
      if !@videoset.blank?
     @comments  = @videoset.video_comments.find(:all,:order => "created_at DESC" )
      end
    @comment = VideoComment.new    
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return     
end




def save_comment 
   if !@videoset.blank?
     @user = User.find(session[:user_id],:select => ["id, screen_name, email"])
     @comments = @videoset.video_comments.find(:all,:order => "created_at DESC")
   if request.post?
       @comment = VideoComment.new(params[:comment]) 
       @comment.user_id = session[:user_id]
       @comment.videoset_id = @videoset.id
       @comment.created_at = Time.now
       @comment.updated_at = Time.now
       if @comment.save!
         flash[:notice] = "Comment was successfully saved"
         redirect_to videocomment_url(:id => @videoset.permalink)
         else
         flash[:notice] = "Unable to save comment"
         render :action => 'comments'         
        end         
      end      
    end
  end



def delete_comment
    comment = VideoComment.find(params[:id])
    videoset = Videoset.find(comment.videoset_id, :select => ["id, permalink"])
    comment.destroy
    flash[:notice] = "Comment was successfully deleted "
    redirect_to :action => 'comments', :id => videoset.permalink
  end

# method to redirect url from map
  def search_map
    #videoset = Videoset.find_by_id(params[:id],:select => ["continent,country,state,location,permalink"])
    #redirect_to videopermalink_url(:continent => videoset.continent, :country=> videoset.country, :state=> videoset.state, :location=> videoset.location, :id => videoset.permalink)
  end 
      
  def search        
    videoset = Videoset.find_by_permalink(params[:id],:select => ["continent,country,state,location,permalink"])
    redirect_to videopermalink_url(:continent => videoset.continent, :country=> videoset.country, :state=> videoset.state, :location=> videoset.location, :id => videoset.permalink)
   end      
      
      
private

 def user_profile_info_with_link
     if !params[:id].blank?   
   @videoset = Videoset.find_by_permalink(params[:id])
   if @videoset
   @user_profile = User.find(@videoset.user_id)  
   
   conditions = ["lat is not null and longt is not null"]
   @user_photsets = @user_profile.photosets.find(:all,:conditions => conditions) 
   @user_videosets = @user_profile.videosets.find(:all,:conditions => conditions)    
   
   conditions = ["lat is not null and longt is not null and status LIKE ?",1]
   @user_reviews_published= @user_profile.reviews.find(:all,:conditions => conditions , :order => 'title ASC') 
   @user_stories_published  = @user_profile.stories.find(:all, :conditions =>  conditions ,:order => 'title ASC')
   @user_travelogs_published = @user_profile.travelogs.find(:all, :conditions =>  conditions ,:order => 'title ASC')
   
   conditions = ["(friend_id LIKE ? or user_id LIKE ?) and (accepted_at is not null)",@user_profile.id,@user_profile.id]
   @user_friends = UserNetwork.find(:all,:conditions => conditions)  
   
   condition =["to_deleted = 0 AND user_read = 0" ]
   @user_messages = @user_profile.to_mails.find(:all, :conditions => condition) 
   else
     render :text => "No profile exists with the scrren name"
     end
   end  
 end


  
end
