class Myworld::PhotosController < ApplicationController
  
   before_filter :authorize_user, :only => [:comments, :save_comment,:delete_comment]
   before_filter :user_profile_info, :only => [:index]
   before_filter :user_profile_info_with_link, :only =>[:preview,:comments,:save_comment]
   before_filter :left_top_adv,:left_bottom_adv,:right_adv, :except => [:preview,:photo,:photo_commnets,:delete_comment]
   layout 'myworld'
 
 
def mail
end  
def index
       @page_title = "#{@user_profile.screen_name} - Photosets"
       conditions = ["lat is not null and longt is not null"]
       select = "title,permalink,coverimage_id,continent,country,state,location"
       @photosets = @user_profile.photosets.paginate :page => params[:page], :per_page => 45, :select => select, :conditions => conditions,:order => 'created_on DESC'
       @total = @photosets.total_entries    
end
     
     
     
# method to display photoset details  
   def preview     
     conditions = ["lat is not null and longt is not null"] 
     select = "title,permalink,coverimage_id,continent,country,state,location"
     @photosets = @user_profile.photosets.paginate :page => params[:page], :per_page => 25, :select => select,:conditions => conditions,:order => 'created_on DESC'
     @total =  @photosets.total_entries 
     select = "id,user_id,title,permalink,coverimage_id"
     @photoset = Photoset.find(:first,:select => select, :conditions => ["permalink LIKE ?",params[:id]])
     @page_title = "Photoset - #{@photoset.title}"
     findall_photoset_advs(@photoset)
     rescue
    flash[:notice] = 'Some thing went wrong!!'
    render :template => 'shared/error'and return 
  end
  
  
  def photo     
        select = "id,photoset_id,title,image,caption"    
        @photo = Photo.find(params[:id],:select => select)
        photoset = Photoset.find(@photo.photoset_id,:select => ["id, user_id"])
      
        @user_photsets = Photoset.find(:all,:conditions => ["user_id like ?", photoset.user_id ])
        render :layout=> false 
  end

  def photo_commnets       
        @photo = Photo.find(params[:id])
        render :layout=> false 
  end
      
      
 # method to display the list of all comments to the photoset
  
  def comments
    @user = User.find(session[:user_id],:select => ["id, screen_name, email"])
    @page_title = "Photoset - #{@photoset.title} - Comments"
    
   if !@photoset.blank?
    @comments = PhotoComment.find(:all,:conditions => ["photoset_id LIKE ?",@photoset.id],:order => "created_at DESC")
    findall_photoset_advs(@photoset)
    end
    @comment = PhotoComment.new    
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return     
end

def save_comment 
   if !@photoset.blank?
      @user = User.find(session[:user_id],:select => ["id, screen_name, email"])
      @comments = PhotoComment.find(:all,:conditions => ["photoset_id LIKE ?",@photoset.id],:order => "created_at DESC")
          if request.post?
              @comment = PhotoComment.new(params[:comment]) 
              @comment.user_id = session[:user_id]
              @comment.photoset_id = @photoset.id
              @comment.created_at = Time.now
              @comment.updated_at = Time.now
              if @comment.save!
                 flash[:notice] = "Comment was successfully posted"
                 redirect_to photocomment_url(:id => @photoset.permalink) and return    
              else
                flash[:notice] = "Unable to post comment"
                render :action => 'comments'and return         
              end  
          else
            redirect_to photocomment_url(:id => @photoset.permalink)  and return          
          end      
        end
 rescue
flash[:notice] = 'Some thing went wrong!!'
render :template => 'shared/error'and return          
end
  
  
def delete_comment
  comment = PhotoComment.find_by_id(params[:id])
    if comment
        photoset = Photoset.find(comment.photoset_id, :select => ["id, permalink,user_id"])
         if photoset.user_id == session[:user_id]
        comment.destroy
        flash[:notice] = "Comment was successfully deleted "
        else
        flash[:notice] = "You didn't have access to delete this comment"   
        end  
        redirect_to :action => 'comments', :id => photoset.permalink and return 
    else
      redirect_to :action => 'index' and return 
    end    
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return        
end


  
  
  def search_map
   photoset =Photoset.find_by_id(params[:id])
   redirect_to photopermalink_url(:continent =>check_content(photoset.continent),:country => check_content(photoset.country), :state => check_content(photoset.state), :location => check_content(photoset.location),:id => photoset.permalink)
  end 
  
  def search
   photoset =Photoset.find_by_permalink(params[:id])
   redirect_to photopermalink_url(:continent =>check_content(photoset.continent),:country => check_content(photoset.country), :state => check_content(photoset.state), :location => check_content(photoset.location),:id => photoset.permalink)
  end  
  
def share_the_love
  @photoset = Photoset.find_by_permalink(params[:id])
 if request.post?
  user = User.find(session[:user_id],:select => "first_name,email,id,screen_name,last_name")   
  sendername = user.first_name.to_s + " " + user.last_name.to_s 
  url = photopermalink_url(:continent => check_content(@photoset.continent),:country => check_content(@photoset.country), :state => check_content(@photoset.state), :location => check_content(@photoset.location),:id => @photoset.permalink) 
  
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
                                          :subject => "Photo's invitaion",
                                          :message => "#{user.screen_name} has Invited you to view his photos.<br/><br/> Click on the below URL to view this Photos.<br/<br/>. <a href='#{url}' target='blank' class='story_view12'>#{url}</a>"
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
                                                Emailer.deliver_photos_invitation(for_user,sendername,url)
                                                #Emailer.deliver_photos_invitation(for_user,user.first_name,url)
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

private

   def findall_photoset_advs(photoset)
           @header_adv = !photoset.photoset_adv.photoset_top_adv.blank? ? photoset.photoset_adv.photoset_top_adv.script : @header_adv 
           @left_top_adv = !photoset.photoset_adv.photoset_left_top_adv.blank? ? photoset.photoset_adv.photoset_left_top_adv.script : left_top_adv
           @left_bottom_adv = !photoset.photoset_adv.photoset_left_bottom_adv.blank? ?  photoset.photoset_adv.photoset_left_bottom_adv.script : left_bottom_adv
           @right = !photoset.photoset_adv.photoset_right_adv.blank? ?  photoset.photoset_adv.photoset_right_adv.script : right_adv
   end
   
 def user_profile_info_with_link
     if !params[:id].blank?   
           @photoset = Photoset.find_by_permalink(params[:id])
           if @photoset
               @user_profile = User.find(@photoset.user_id)  
               conditions = ["lat is not null and longt is not null"]
               @user_photsets = @user_profile.photosets.find(:all,:conditions => conditions) 
               #@user_videosets = @user_profile.videosets.find(:all,:conditions => conditions)    
               conditions = ["lat is not null and longt is not null and status LIKE ?",1]
               #@user_reviews_published= @user_profile.reviews.find(:all,:conditions => conditions , :order => 'title ASC') 
               @user_stories_published  = @user_profile.stories.find(:all, :conditions =>  conditions ,:order => 'title ASC')
               #@user_travelogs_published = @user_profile.travelogs.find(:all, :conditions =>  conditions ,:order => 'title ASC')
               conditions = ["(friend_id LIKE ? or user_id LIKE ?) and (accepted_at is not null)",@user_profile.id,@user_profile.id]
               @user_friends = UserNetwork.find(:all,:conditions => conditions)
               
               if !session[:user_id].blank?
                     condition =["to_deleted = 0 AND user_read = 0" ]
                     @user_messages = @user_profile.to_mails.find(:all, :conditions => condition) 
               end
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
