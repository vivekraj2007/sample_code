class Admin::UsersController < ApplicationController
  before_filter :authorize_admin
  layout 'admin'
  
  
  
  
  
  def index
  page = params[:page].blank? ? 1 : params[:page]
  sort = case params['sort']
   when "screen_name"  then "screen_name"  
   when "email" then "email"
   when "activated_at" then "activated_at"
   when "created_at" then "created_at"
   when "country" then "countries.name"
   when "screen_name_reverse"  then "screen_name DESC"
   when "email_reverse"  then "email DESC"
   when "activated_at_reverse"  then "activated_at DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "country_reverse"  then "countries.name DESC"
   end   
    
    sort = sort.blank? ? "created_at DESC" : sort
   
    if !params[:search].blank?
    condition = ["	screen_name like ? or last_name like ? or middle_name like ? or first_name like ? or city like ? or zip like ? or countries.name like ?", "%"+params[:search]+"%",params[:search],params[:search],params[:search],params[:search],params[:search],params[:search]]
    #session[:condition] = condition
    else
    condition = ""
    end  

    
    @users = User.paginate :per_page=>25, :page=> page, :order=>sort , :conditions => condition , :include => "country"   
  end
  
  
  def profile
   @user  = User.find(params[:id])
 end  
 
 def edit_profile
   @user  = User.find(params[:id])
   @profile = @user.profile
  if request.post?
        address = Country.get_alt_longt(params[:user][:city],params[:user][:country_id])   
        if  address == nil
              flash[:notice] = "unknown city for the selected country"
               render :action => 'edit_profile'and return
        else
              @user.lat = address.latitude
              @user.longt = address.longitude        
            end   
       Add_explored_places(@user.profile,params[:explorer_list],'explorer_list')       
        @user.attributes = params[:user]      
        @user.profile.update_attributes(params[:profile])    
         if @user.save
            flash[:notice] = 'User profile was successfully updated.'
            redirect_to :action => 'profile', :id => @user.id  
         else
            flash[:notice] = 'Unable to update user details.'
            render :action => 'edit_profile' and return  
         end   
  end
   
 end


 # method to send email for account activation.
 def send_account_notification
  @user  = User.find_by_id(params[:id]) 
  begin     
     url = "http://www.uncharted.net/account/activation/#{@user.activation_code}" 
     Emailer.deliver_admin_accountactivation(@user.email,url)	
   end
   flash[:notice] = "Email has been sent to #{@user.email} to active his account."
   redirect_to :action => 'index'
 end  
 
def account_activation
    @user  = User.find_by_id(params[:id])
    @user.activated_at=Time.now
       if @user.update_attributes(params[:user])
         flash[:notice] = "User account was successfully activated. now this user can be displayed in the live site."      
      else
         flash[:notice] = "Unable to activate user account."
      end  
    redirect_to :action => 'profile',:id => @user.id
end
  
   
 def delete_profile
   User.find(params[:id]).destroy
   flash[:notice] = "User was successfully deleted"
   redirect_to :action => 'index'   
 end
 
 def send_emailnotification
   @user = User.find(params[:id])
   if request.post?
       Emailer.deliver_admin_usermessage(@user.screen_name,@user.email,params[:message])
       @message = "Email send"
     end
     render :layout => false
 end 
 
 
  # method to add altitue and longt to all users   
     def add_lat_longt
       users = User.find(:all)
           for user in users
                  if !user.city.blank? && !user.country_id.blank?
                  address = Country.get_alt_longt(user.city,user.country_id)
                      if address != nil
                      user.update_attributes(:lat => address.latitude, :longt => address.longitude)
                     end
                 end
           end   
         end  
         
   # method to add user_settings for users

def add_user_settings
   users = User.find(:all)
   for user in users
   user_settings = UserSetting.create(:user_id=>user.id)
   end
end
         
public

def Add_explored_places(profile,explored,type) 
    if !explored.blank?
        filters=Array.new
        for list in explored
        filters << list
        end
     end      
  if type == "explorer_list"       
      if filters.blank?     
        profile.update_attributes(:explorer_list => nil)
        else
       profile.update_attributes(:explorer_list => filters.join(','))
      end    
  elsif type == "exploredplaces_list" 
      if filters.blank?     
        profile.update_attributes(:exploredplaces_list => nil)
        else
      profile.update_attributes(:exploredplaces_list => filters.join(','))
      end
  elsif type == "why i am here"   
      if filters.blank?     
        profile.update_attributes(:description => nil)
        else
      profile.update_attributes(:description => filters.join(','))
      end    
   end   
 end  
         
         
 
end
