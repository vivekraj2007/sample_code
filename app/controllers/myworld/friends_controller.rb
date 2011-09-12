class Myworld::FriendsController < ApplicationController
  

   before_filter :authorize_user, :only => [:add_friend] 
   before_filter :user_information, :only => [:add_friend] 
   before_filter :user_profile_info, :only => [:index]
   before_filter :left_top_adv,:left_bottom_adv,:right_adv
   layout 'myworld'
   
def index
  friends= Array[]
  friends = list_friends(@user_profile)   
  if request.post?
     conditions = ["id like ?",params[:friend_name]]
    @friends = User.paginate :page => params[:page], :per_page => 45, :conditions => conditions
          if !friends.blank?
          conditions = ["id in (#{@network_friends.join(",")})"]
          @total = User.find(:all,:conditions => conditions)   
          else
          @friends =  @total = ""      
          end  
  else   
          if !friends.blank?
          conditions = ["id in (#{@network_friends.join(",")})"]
          @friends = User.paginate :page => params[:page], :per_page => 45, :conditions => conditions
          @total = User.find(:all,:conditions => conditions)   
          else
          @friends =  @total = ""     
          end  
  end
  
  
 end
  
  
  def add_friend 
    screenname = params[:id].gsub('_', ' ')
    if friend = User.find_by_screen_name(screenname)  
    conditions = ["(user_id LIKE ? AND friend_id LIKE ? ) OR (user_id LIKE ? AND friend_id LIKE ?)",session[:user_id],friend.id,friend.id,session[:user_id]]
    user = UserNetwork.find(:first,:conditions => conditions )
    
    if user
        flash[:notice] = "You have already added #{friend.screen_name} to your friends list"
         redirect_to profile_url(:id => friend.screen_name.gsub(' ', '_'))
        
    else    
      
        if friend.id == session[:user_id]
          flash[:notice] = "You can't add yourself to your friends list"
         redirect_to profile_url(:id => friend.screen_name.gsub(' ', '_')) 
       else      
           user_network = {
          :user_id => session[:user_id], 
          :friend_id => friend.id,
          :requested_at => Time.now,
           :comment => "test message"
          #:comment => params[:message][:message].gsub("\n", "<br />")
            } 
           user_message = {
          :from_user => session[:user_id], 
          :to_user => friend.id,
          :date_sent => Time.now,
          :subject => "friends request",
          :message => "#{session[:user_screenname]} has sent a friends request."
            } 
        user_mail = UserMail.create(user_message)
        @user_friends = UserNetwork.create(user_network)
        flash[:notice] = "A request has been sent to this user."
        redirect_to profile_url(:id => friend.screen_name.gsub(' ', '_'))
        end
    end
    else
    flash[:notice] = "Unable to add this user to your friends list"
    redirect_to friends_url(:id => @user_profile.screen_name.gsub(' ', '_'))     
    end  
  end  
  
  
  private

def list_friends(profile)
@network_friends = Array[]
 useradd = UserNetwork.find(:all, :conditions=>["user_id Like ? AND accepted_at is not null",profile.id])
             if !useradd.blank?
               for user in useradd
               @network_friends.push("'"+user.friend_id.to_s+"'")
              end
             end
  userfrd = UserNetwork.find(:all, :conditions=>["friend_id Like ? AND accepted_at is not null",profile.id])
            if !userfrd.blank?
              for user in userfrd
              @network_friends.push("'"+user.user_id.to_s+"'")
              end
            end 
  return @network_friends
end
  
  
end
