class Myworld::StoriesController < ApplicationController
  
   before_filter :authorize_user, :only => [:comments,:save_comment,:delete_comment]
   before_filter :user_profile_info, :only =>[:index]
   before_filter :user_profile_info_with_link, :only =>[:preview,:comments,:save_comment]
   before_filter :left_top_adv,:left_bottom_adv,:right_adv
   layout 'myworld'
   
  def index
       @page_title = "#{@user_profile.screen_name} - Stories"
       conditions = ["lat is not null and longt is not null and status LIKE ?",1]
       @stories = @user_profile.stories.paginate :page => params[:page], :per_page => 5, :conditions => conditions, :order => 'updated_at DESC'
       @total =   @stories.total_entries  
  end
  
  
  # method to display story details  
def preview
     if request.post? || !params[:id].blank?
        @story = Story.find_by_permalink(params[:id])
        @page_title = "Story - #{@story.title}"
          if !@story.story_adv.story_top_adv.blank?
          @header_adv = @story.story_adv.story_top_adv.script
          end
    else
        redirect_to :action => "index"  
    end          
   #~ rescue
    #~ flash[:notice] = 'Some thing went wrong!!'
    #~ render :template => 'shared/error'and return 
end
    
def photo       
    @photo = Photo.find(params[:id])
    render :layout=> false 
end 
      
      
  # method to display the list of all comments to the story  
def comments
    @user = User.find(session[:user_id], :select => ["screen_name,email"])
    @page_title = "Story - #{@story.title} - Comments"
    if !@story.blank?
    @comments = @story.story_comments.find(:all)
    end
    @comment = StoryComment.new    
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return     
end


  
def save_comment
     if !@story.blank?
        @page_title = "Story - #{@story.title} - Comments"
         @comments = @story.story_comments.find(:all)
           if request.post?
             @comment = StoryComment.new(params[:comment]) 
             @comment.user_id = session[:user_id]
             @comment.story_id = @story.id
             @comment.created_at = Time.now
             @comment.updated_at = Time.now
               if @comment.save!
                  flash[:notice] = "Comment was successfully posted"
                  redirect_to :action => 'comments', :id => @story.permalink
               else
                  flash[:notice] = "Unable to post comment"
                  render :action => 'comments'         
                end 
           else
           redirect_to :action => 'comments', :id => @story.permalink
         end  
       end
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return         
end
  
  
def delete_comment
    comment = StoryComment.find_by_id(params[:id])
       if comment
           story= Story.find(comment.story_id, :select => ["id, permalink,user_id"])
            if story.user_id == session[:user_id]
            comment.destroy
              flash[:notice] = "Comment was successfully deleted "
            else
              flash[:notice] = "You didn't have access to delete this comment"  
            end    
            redirect_to :action => 'comments', :id => story.permalink and return
       else
           redirect_to :action => 'index' and return
       end
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return          
end
  
  
  
 # method to find story and redirect to permalink url page
  def search
    if request.post?
      story = Story.find_by_permalink(params[:search])
        if story
        redirect_to storypermalink_url(:continent => check_content(story.continent), :country =>check_content(story.country) ,:state =>check_content(story.state) , :location =>check_content(story.location) ,:id => check_content(story.permalink) )
        else
        redirect_to :action => 'index'and return        
        end  
    else
      flash[:notice] = "Please select a story"  
      redirect_to :action => 'index'and return       
    end
   rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return       
 end

 # method to find story comments and redirect to permalink url page
  def comments_search
  if request.post?
       story = Story.find_by_permalink(params[:search])
        if story
        redirect_to story_comment_url(:id => story.permalink)
        else
        redirect_to :action => 'index'    
      end       
  else
      flash[:notice] = "Please select a story"  
      redirect_to :action => 'index'  
  end    
end

  #method for rating 
  def rate 
    @story =   Story.find(params[:id])  
    if !@story.blank?      
     @user = User.find(session[:user_id])
     @story.add_rating Rating.new(:rating => params[:rating], :user_id => @user.id,  :rateable_id => @story.id, :rateable_type => 'story') 
     @story.update_attributes(:user_rating => @story.rating)
    end
    
  end
  
  
  def share_the_love
  @story = Story.find_by_permalink(params[:id])
   if request.post?
  user = User.find(session[:user_id],:select => "first_name,email,id,screen_name,last_name")   
  sendername = user.first_name.to_s + " " + user.last_name.to_s 
  url = storypermalink_url(:continent => check_content(@story.continent),:country => check_content(@story.country), :state => check_content(@story.state), :location => check_content(@story.location),:id => @story.permalink) 
  
  total_invitations = params[:invitation].gsub(/, /,',')
  emails = total_invitations.split(',')
  
  count = 0 
  @sucess_count = 0
  email_exp = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
  @sent_invitations = Array.new
  
  
 emails.size.times do   
        
      if !@sent_invitations.include?("#{emails[count]}")

         
          invited_friends = User.find(:first, :conditions => ["screen_name LIKE ?",emails[count]], :select => 'id,email,screen_name')
                  if !invited_friends.blank?
                    
                                   if invited_friends.email != user.email                          
                                           user_message = {
                                          :from_user => user.id, 
                                          :to_user => invited_friends.id,
                                          :date_sent => Time.now,
                                          :subject => "Stories invitaion",
                                          :message => "#{user.screen_name} has Invited you to view his Story.<br/><br/> Click on the below URL to view this Story.<br/<br/>. <a href='#{url}' target='blank' class='story_view12'>#{url}</a>"
                                            } 
                                          if UserMail.create(user_message)
                                          @sucess_count = @sucess_count+1  
                                          @sent_invitations.push(emails[count])                        
                                         end  
                                  else
                                   @user_itself = "You can’t send invitation to your self"    
                                  end       
                  else
                                 for_user = emails[count].gsub(/ /,'')
                                  if for_user   != user.email  
                                        if for_user.match(email_exp)                 
                                                begin 
                                                Emailer.deliver_story_invitation(for_user,sendername,url)
                                                #Emailer.deliver_story_invitation(for_user,user.first_name,url)
                                                @sucess_count = @sucess_count+1
                                                @sent_invitations.push(for_user)  
                                              end  
                                        end                          
                                 else
                                       @user_itself = "You can’t send invitation to your self" 
                                 end              
                end 
             
      end
      count = count+1
      @message = "#{@sucess_count} invitation(s) sent."
  end

end
  render :layout => false 
end
  
  
  
  
  
  
  
  
  
  
  
  
  
  # method to redirect url from map
  def search_map
       story = Story.find_by_id(params[:id],:select => ["continent,country,state,location,permalink"])
      redirect_to storypermalink_url(:continent => check_content(story.continent), :country =>check_content(story.country) ,:state =>check_content(story.state) , :location =>check_content(story.location) ,:id => check_content(story.permalink) )
 end 
  
  
  #~ public
  
  #~ def story_advertisements
   #~ @top_adv = Advertisement.find(1)
   #~ @bottom_adv = Advertisement.find(6)    
 #~ end   
 
 private

 def user_profile_info_with_link
     if !params[:id].blank?   
         @story = Story.find_by_permalink(params[:id])
         if @story
             @user_profile = User.find(@story.user_id)  
             
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
            redirect_to home_url    
          end
     else
        redirect_to home_url            
   end  
 end
 
  
  def check_content(content)
   if !content.blank?
     return content.gsub(/ /,'-')
  end
end
  
end
