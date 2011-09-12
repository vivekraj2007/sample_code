class Myworld::TravelogsController < ApplicationController
  before_filter :authorize_user, :only => [:comments, :save_comment]
  before_filter :user_profile_info, :only =>[:index]
  before_filter :user_profile_info_with_link, :only =>[:preview,:comments,:save_comment]
 #  before_filter :travelog_advertisements
  layout 'myworld'
   
  def index
       conditions = ["status LIKE ?",1]
       @travelogs = @user_profile.travelogs.paginate :page => params[:page], :per_page => 5, :conditions => conditions, :order => 'title ASC'
       @total = @user_profile.travelogs.find(:all,:conditions => conditions,:select => "id")  
  end
  
  
  #~ def search
    #~ search_word = params[:search]
    #~ conditions = ["user_id LIKE ? AND (title LIKE ? OR tag LIKE ? OR write_it LIKE ?)",session[:user_id],search_word,search_word,search_word]
    #~ @travelogs = Travelog.paginate :page => params[:page], :per_page => 5, :conditions => conditions
    #~ @total = Travelog.find(:all,:conditions => conditions)
    #~ @message = "No stories found."
    #~ render :action => 'index'
 #~ end

  # method to display story details
  
   def preview
     if request.post? || !params[:id].blank?
    @travelog = @user_profile.travelogs.find_by_permalink(params[:id])
    else
    redirect_to :action => "index"  
    end    
   rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
  end
    
    
  # method to display the list of all comments to the story
  
  def comments
    @user = User.find(session[:user_id])
    #@travelog = Travelog.find_by_permalink(params[:id])
    if !@travelog.blank?
    @comments = TravelogComment.find(:all,:conditions => ["user_id LIKE ? AND travelog_id LIKE ?",session[:user_id], @travelog.id])
    end
    @comment = TravelogComment.new    
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return     
end


  
  def save_comment
    #@travelog = Travelog.find_by_permalink(params[:id])
   if !@travelog.blank?
    @comments = TravelogComment.find(:all,:conditions => ["user_id LIKE ? AND travelog_id LIKE ?",session[:user_id],@travelog.id])
   if request.post?
       @comment = TravelogComment.new(params[:comment]) 
       @comment.user_id = session[:user_id]
       @comment.travelog_id = @travelog.id
       @comment.created_at = Time.now
       @comment.updated_at = Time.now
       if @comment.save!
         flash[:notice] = "Comment was successfully saved"
         redirect_to :action => 'comments', :id => @travelog.permalink
         else
         flash[:notice] = "Unable to save comment"
         render :action => 'comments'         
        end         
      end      
    end
  end
  
  
 # method to display map for the selected story 
def map
  @travelog = Travelog.find(:first,:conditions => ["user_id LIKE ? AND permalink LIKE ?",session[:user_id],params[:id]])
   rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
end
  
    #method for rating 
  def rate 
    @travelog =   Travelog.find(params[:id])  
    if !@travelog.blank?      
     @user = User.find(session[:user_id])
     @travelog.add_rating Rating.new(:rating => params[:rating], :user_id => @user.id,  :rateable_id => @travelog.id, :rateable_type => 'travelog') 
     @travelog.update_attributes(:user_rating => @travelog.rating)
    end
    
  end
  
  
    # method to redirect url from map
  def search_map
       #~ travelog = Travelog.find_by_id(params[:id],:select => ["continent,country,state,location,permalink"])
      #~ redirect_to travelogpermalink_url(:continent => check_content(travelog.continent), :country =>check_content(travelog.country) ,:state =>check_content(travelog.state) , :location =>check_content(travelog.location) ,:id => check_content(travelog.permalink) )
 end 
  
  
  public
  
  #~ def story_advertisements
   #~ @top_adv = Advertisement.find(1)
   #~ @bottom_adv = Advertisement.find(6)    
 #~ end   
 
 private

 def user_profile_info_with_link
     if !params[:id].blank?   
   @travelog = Travelog.find_by_permalink(params[:id])
   if @travelog
   @user_profile = User.find(@travelog.user_id)  
   @user_photsets = @user_profile.photosets.find(:all) 
   @user_videosets = @user_profile.videosets.find(:all) 
   @user_reviews_published= @user_profile.reviews.find(:all,:conditions => ["status LIKE ?",1],:order => 'title ASC') 
   @user_stories_published  = @user_profile.stories.find(:all, :conditions => ["status LIKE ?",1],:order => 'title ASC')
   @user_travelogs_published = @user_profile.travelogs.find(:all, :conditions => ["status LIKE ?",1],:order => 'title ASC')
  conditions = ["(friend_id LIKE ? or user_id LIKE ?) and (accepted_at is not null)",@user_profile.id,@user_profile.id]
   @user_friends = UserNetwork.find(:all,:conditions => conditions)  
   condition =["to_deleted = 0 AND user_read = 0" ]
   @user_messages = @user_profile.to_mails.find(:all, :conditions => condition) 
   else
     render :text => "No profile exists with the scrren name"
     end
   end  
 end
 
    def check_content(content)
   if !content.blank?
     return content.gsub(/\?/,'-')
  end
end

end
