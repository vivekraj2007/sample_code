class Myworld::ReviewsController < ApplicationController
  before_filter :authorize_user, :only => [:rate,:comments, :save_comment]  
  before_filter :user_profile_info, :only =>[:index]
  #~ before_filter :user_profile_info
  before_filter :user_profile_info_with_link, :only =>[:preview,:comments,:save_comment]
  
  layout 'myworld'
 
  def index
       conditions = ["status LIKE ?",1]
       @reviews = @user_profile.reviews.paginate :page => params[:page], :per_page => 5, :conditions => conditions, :order => 'title ASC'
       @total = @user_profile.reviews.find(:all,:conditions => conditions,:select => "id") 
 end 
  
# method to display review details
  
   def preview
     if request.post? || !params[:id].blank?
    @review = @user_profile.reviews.find_by_permalink(params[:id])
    else
    redirect_to :action => "index"  
    end    
   rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
  end
  
  
  # method to display the list of all comments to the review
  
  def comments
    @user = User.find(session[:user_id])
    #@review = Review.find_by_permalink(params[:id])
    if !@review.blank?
    @comments = ReviewComment.find(:all,:conditions => ["user_id LIKE ? AND review_id LIKE ?",session[:user_id], @review.id])
    end
    @comment = ReviewComment.new    
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return     
end


 def save_comment
    #@review = Review.find_by_permalink(params[:id])
   if !@review.blank?
     @comments = ReviewComment.find(:all,:conditions => ["user_id LIKE ? AND review_id LIKE ?",session[:user_id],@review.id])
      if request.post?
       @comment = ReviewComment.new(params[:comment])
        #~ @comment.comment=params[:comment][:comment]       
       @comment.user_id = session[:user_id]
       @comment.review_id = @review.id
       @comment.created_at = Time.now
       @comment.updated_at = Time.now
       if @comment.save!
         flash[:notice] = "Comment was successfully saved"
         redirect_to :action => 'comments', :id => @review.permalink
         else
         flash[:notice] = "Unable to save comment"
         render :action => 'comments'         
        end         
      end      
    end
  end

     
  
   #method for rating 
  def rate 
    @review =   Review.find(params[:id])  
   if !@review.blank?      
     @user = User.find(session[:user_id])
     @review.add_rating Rating.new(:rating => params[:rating], :user_id => @user.id,  :rateable_id => @review.id, :rateable_type => 'review') 
     @review.update_attributes(:user_rating => @review.rating)
    end
    
  end
  
  
      # method to redirect url from map
  def search_map
       #~ review = Review.find_by_id(params[:id],:select => ["continent,country,state,location,permalink"])
      #~ redirect_to reviewpermalink_url(:continent => check_content(review.continent), :country =>check_content(review.country) ,:state =>check_content(review.state) , :location =>check_content(review.location) ,:id => check_content(review.permalink) )
 end 
  
  
   private

 def user_profile_info_with_link
     if !params[:id].blank?   
   @review = Review.find_by_permalink(params[:id])
   if @review
   @user_profile = User.find(@review.user_id)  
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
