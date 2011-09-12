class Myworld::MessagesController < ApplicationController
 
  before_filter :authorize_user 
  before_filter :selfauthorize, :only => [:index]
  before_filter :user_profile_info, :only => [:sent_message_details,:inbox_message_details,:index,:view_message,:new_message,:create_message,:reply_message,:sent_messages,:sentmsg_delete,:inboxmsg_delete,:totalmessages] 
  before_filter :user_information,:only =>[:send_message,:accept_request_from,:decline_request_from]
  before_filter :myworld_advertisements
  layout 'myworld'
  
 
 # inbox messages 
def index  
      if request.post?
        condition =["from_user LIKE ?",params[:messaged][:user]]
        @inbox_messages = @user_profile.to_mails.paginate :page => params[:page], :per_page => 20, :conditions => condition
      else        
        @inbox_messages = @user_profile.to_mails.paginate :page => params[:page], :per_page => 20
      end 
     @page_title = "#{@user_profile.screen_name.gsub(' ', '_')} - Inbox messages"    
    @total = @user_profile.to_mails.find(:all,:select => "id,from_user") 
    @messaged_users = !@total.blank? ?  messaged_users_list(@total,"indoxmails") : nil
end  
   
   
   
# sent messages
def sent_messages 
       if request.post?
         condition =["to_user LIKE ?",params[:messaged][:user]]
         @sent_messages = @user_profile.from_mails.paginate :page => params[:page], :per_page => 20, :conditions => condition
      else
         @sent_messages = @user_profile.from_mails.paginate :page => params[:page], :per_page => 20
       end
     @page_title = "#{@user_profile.screen_name.gsub(' ', '_')} - Sent messages"  
     @total = @user_profile.from_mails.find(:all, :select => "id,to_user")  
   @messaged_users = !@total.blank? ?  messaged_users_list(@total,"sendmails") : nil
end  
   
   
   
# message details  
def view_message
  condition =["id LIKE ?",params[:message]]
  @selected_message =  UserMail.find(:first, :conditions => condition)  
      # inbox 
            if session[:user_id] == @selected_message.to_user
              @selected_message.update_attributes(:user_read => 1)
             redirect_to :action => "inbox_message_details",:id => @user_profile.screen_name.gsub(' ', '_'), :page => params[:position]==0 ? 1 : params[:position] and return 
           end   
       # send 
          if session[:user_id] == @selected_message.from_user
            redirect_to :action => "sent_message_details",:id => @user_profile.screen_name.gsub(' ', '_'), :page => params[:position]==0 ? 1 : params[:position] and return 
          end

end  
  
   
  def inbox_message_details
   @page_no = params[:page] 
   @inbox_messages = @user_profile.to_mails.paginate :page => params[:page], :per_page => 1   
  @total = @user_profile.to_mails.find(:all,:select => "id")  
  @message = UserMail.new  
  @selected_message = @inbox_messages[0]
  render :action => "inbox_message"        
  end  
 
  def sent_message_details
   @page_no = params[:page] 
  @sent_messages = @user_profile.from_mails.paginate :page => params[:page], :per_page => 1
  @total = @user_profile.from_mails.find(:all,:select => "id")  
  @message = UserMail.new  
  @selected_message = @sent_messages[0]
  render :action => "sent_message"        
  end 
  
  
  
  def send_message
  @message = UserMail.new
  @message.email_address = params[:id]  
  render :action => 'new_message'
  end  
  
  def new_message
    @page_title = "#{@user_profile.screen_name.gsub(' ', '_')} - Write new messages"  
    @message = UserMail.new    
  end  
 
  
def create_message
    if request.post?
     emails = params[:message][:email_address].split(',') unless !emails.blank?
     count = 0 
     @unfind_list = Array[] 
     @found_list = Array[] 
     emails.size.times do
      member = User.find(:first,:conditions => ["email like ? OR screen_name LIKE ?",emails[count],emails[count]])
            if member
               unless @found_list.include?(member.id)
               @found_list.push(member.id)
              loginuser = session[:user_id]
              submit_message = UserMail.create(:from_user =>loginuser,:to_user =>member.id,:date_sent=>Time.now,:subject => params[:message][:subject],:message =>params[:message][:message])             
               end               
            else
           @unfind_list.push(emails[count])
            end
        count = count+1
      end
      else
       #render :action => 'new_message'and return
       redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) and return 
     end 
     flash[:notice] = "Your message has been sent"
     redirect_to sent_messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) 
end
 
 
 
 
 def reply_message   
  @inbox_messages = @user_profile.to_mails.paginate :page => params[:page], :per_page => 20
  @total = @user_profile.to_mails.find(:all,:select => "id")   
       if request.post?     
         @selected_message = UserMail.find(params[:message_id]) 
          user_mail = {
          :from_user => @user_profile.id, 
          :to_user => @selected_message.from_user,
          :subject => params[:message][:subject],
          :message => params[:message][:message].gsub("\n", "<br />"),
          :date_sent => Time.now
        }  
        @message = UserMail.new(user_mail)
           if @message.save!
            flash[:notice] = "Reply has been sent."
            redirect_to sent_messages_url(:id => @user_profile.screen_name.gsub(' ', '_'))
            else
            flash[:notice] = "Unable to send reply"  
            render view_message_url(:id => @user_profile.screen_name.gsub(' ', '_'),:message => @selected_message.id)
            end      
        end    
 end  
 

  
def sentmsg_delete
    message = @user_profile.from_mails.find(params[:message])
    if message
         if message.update_attributes(:from_deleted => 1)
           flash[:notice] = "message was successfully deleted"
        else
           flash[:notice] = "unable to delete selected message" 
       end  
   else
        flash[:notice] = "unable to delete selected message" 
   end
    redirect_to sent_messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) 
end  
  
def inboxmsg_delete
    message = @user_profile.to_mails.find(params[:message])
    if message
        if message.update_attributes(:to_deleted => 1)
          flash[:notice] = "message was successfully deleted"
        else
          flash[:notice] = "unable to delete selected message" 
       end  
   else
       flash[:notice] = "unable to delete selected message" 
   end
    redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) 
end  
  
  
# method to accept friends request and delete the 'accept'- 'delete' message"
  def accept_request_from    
  message =  UserMail.find(:first, :conditions =>["id like ? and subject like ?",params[:message],"friends request"])
  if !message.blank?
     if user_network = UserNetwork.find(:first, :conditions =>["user_id like ? and friend_id like ?",message.from_user,message.to_user])
            if user_network.update_attributes(:accepted_at => Time.now)
                message.destroy
                flash[:notice] = "#{message.from_id.screen_name} was successfully added to your friends list"
                redirect_to friends_url(:id => @user_profile.screen_name.gsub(' ', '_'))
            else
                flash[:notice] = "unable to add #{message.from_id.screen_name} to your friends list"
                redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) 
            end
      else
            flash[:notice] = "unable to add #{message.from_id.screen_name} to your friends list"
            redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_'))   
      end      
  else
     flash[:notice] = "Acess denied for this action."
     redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) 
   end    
  end    



  
  # method to decline friend request and send an message about declining the message
  def decline_request_from    
  message =  UserMail.find(:first, :conditions =>["id like ? and subject like ?",params[:message],"friends request"]) 
  if !message.blank?
      if user_network = UserNetwork.find(:first, :conditions =>["user_id like ? and friend_id like ?",message.from_user,message.to_user])
      if user_network.destroy   
         user_message = {
          :from_user => session[:user_id], 
          :to_user => message.from_user,
          :date_sent => Time.now,
          :subject => "friends request declined",
          :message => "your request for adding as friend has been declined"
            } 
         user_mail = UserMail.create(user_message)
        message.destroy
         flash[:notice] = "decline message was successfully sent."
        redirect_to sent_messages_url(:id => @user_profile.screen_name.gsub(' ', '_'))  
        else
         flash[:notice] = "unable to send decline message to #{message.from_id.screen_name} at this time."
        redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_'))           
        end
      else
        flash[:notice] = "unable to send decline message to #{message.from_id.screen_name} at this time."
        redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_'))        
      end
      
   else   
    flash[:notice] = "Acess denied for this action."
     redirect_to messages_url(:id => @user_profile.screen_name.gsub(' ', '_')) 
  end

  end  
  
  def totalmessages
    condition =["to_deleted = 0 AND user_read = 0" ]
   @user_messages = @user_profile.to_mails.find(:all, :conditions => condition)  
   render :layout => false   
  end  
  
  
   public
  
  def myworld_advertisements
   @top_adv = Advertisement.find(1)
   @bottom_adv = Advertisement.find(6)    
 end 
  
    private
  
   def messaged_users_list(messages_list,type)
     list = Array[] 
         if type == "sendmails"
             messages_list.each do |user| 
                 if  !list.include?(user.to_user)
                 list.push(user.to_user)
                 end
               end  
        elsif type == "indoxmails"
             messages_list.each do |user| 
                 if  !list.include?(user.from_user)
                 list.push(user.from_user)
                 end
               end     
             end 
             
             
               if !list.blank?      
                  messaged_users = User.find(:all, :conditions => ["id in (#{list.join(",")}) AND activated_at is not null"],:select => "id,screen_name")  
               else
                 messaged_users = nil
               end  
    end

  def selfauthorize
    if session[:user_screenname] != params[:id]
    redirect_to messages_url(:id => session[:user_screenname])    
    end  
  end
  
end
