require 'google_geocode'

class AccountController < ApplicationController
 
 before_filter :authorize_user, :only => [:change_password,:edit,:update,:update_exploredplaces,:update_explorertype,:change_photo,:signout]
 
 before_filter :user_information, :only => [:change_password,:myworld,:update,:change_password,:change_photo,:edit,:update_explorerplaces,:update_explorertype]

 # method to find layout map content
 before_filter :layout_map, :only => [:index,:register,:contact_us,:contact_msg,:forgot_password]
 
 
 layout 'account'
 
# method to display home page
 def index
   @page_title = " Explore. Live. Feel."   
   home_page = DefaultAd.find_by_id(1)
   homepage_adv = !home_page.advertisement_id.blank? ? home_page.adv_list.script :  nil
   @header_adv = homepage_adv.blank? ? @header_adv : homepage_adv
end  
 
 
# method for registration page
def register
  #~ if !session[:user_id].blank?
    #~ redirect_to( profile_url(:id => session[:user_screenname])) and return
  #~ else  
  @page_title = "Register for New Account"
  @user = User.new  
 #~ end
end

def contact_us
  #~ render :text => 'contact us' and return
  if request.post?
            Emailer.deliver_contact_form(params[:contact][:name],params[:contact][:email],params[:contact][:message])
             flash[:notice] = "Thanks for your interest in Uncharted. An email has been sent to our
 team and we will do our best to contact you as quickly as possible" 
            redirect_to :action => "contact_msg"
  else      
           render :action => 'contact_us'
  end

end

def under_working
  render :layout => false 
end

def contact_msg
 end

# method to save registration details(validations) and send email activation code to user email id
def create
 @page_title = "User Registration"  
 @user = User.new(params[:user])
      if request.post?      
        # validating latitude and logitude and zip code
        address = Country.get_alt_longt(params[:user][:city],params[:user][:country_id])   
           if  address == nil
             @address_message = "unknown city for the selected country"
             render :action => 'register' and return
          else
            @user.lat = address.latitude
            @user.longt = address.longitude  
             # zip code validation            
            #~ country,state,zipcode = Country.zip(params[:user][:country_id],params[:user][:zip])
                 #~ if country.nil? 
                    #~ @zipcode_message = "Invalid zipcode for the selected country"
                    #~ render :action => 'register' and return   
                #~ else
                   #~ @user.state = state
                #~ end
           end 
        @user.activation_code = User.generate_activation_code 
        if @user.save
           @profile = Profile.create(:user_id=>@user.id)
           @wantto = Wanttoplace.create(:user_id=>@user.id)
           user_settings = UserSetting.create(:user_id=>@user.id)
             begin     
             url = "http://www.uncharted.net/account/activation/#{@user.activation_code}" 
             Emailer.deliver_new_account(@user.email,params[:user][:password],url)	
             end
           render :action => "send_mail"
        else      
           render :action => 'register'
       end
   else
          redirect_to :action => 'register'
   end
        
end

# method for user login
def login   
  if request.post?     
      session[:user] = User.authenticate(params[:email], params[:password])
      if session[:user] 
             if session[:user].activated_at.blank?
                session[:user] = nil
                flash[:login_falied] = "Please activate your account"
                redirect_to :action=>:register   and return
             else
                    session[:user_id] = session[:user].id
                    session[:user_screenname] = session[:user].screen_name.gsub(' ', '_')
                      if params[:remember]
                         cookies[:email] = { :value => params[:email], :expires => 20.days.from_now }
                         cookies[:password] = { :value => params[:password], :expires => 20.days.from_now }
                     else
                         cookies.delete  :email 
                         cookies.delete :password
                    end      
                  user_login = User.find(session[:user_id])
                 user_login.update_attributes(:last_login => Time.now)
                 flash[:notice] = "You have successfully logged in" 
                   if !params[:usrpath].blank? 
                    session[:original_uri]  = params[:usrpath]
                  end
                 uri = session[:original_uri]        
                session[:original_uri] = nil
                redirect_to(uri || profile_url(:id => session[:user_screenname])) and return
              end
              
      else
           flash[:login_falied] = "Invalid login details"
           redirect_to request.env['HTTP_REFERER']   and return
         end
   else
     flash[:login_falied] ="Please login"
     render :action=> :register   and return
  end
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return  
end  


# method to activate user account  
 def activation
   @page_title = "Account Activation"  
   if !params[:id].blank?
     @user = User.find_by_activation_code(params[:id])
          if @user
            @user.activated_at=Time.now
            if @user.update_attributes!(params[:user])
                flash[:login_falied] = 'please login..'         
                render :action => 'account_activated'
            else
                @message  = "Invalid Activation code."    
                render :action => 'message'
            end  
         else
           @message = "Invalid Activation code."      
           render :action => 'message'
         end     
   else
      @message  = "Invalid Activation code."    
      render :action => 'message'
   end  
end 
  
# method to generate new password and send email with new passwotd  
def forgot_password      
@page_title = "Forgot Password"   
  if request.post?
     email = params[:email][:email]
     @user = User.find_by_email(params[:email][:email])
      if @user      
        password = @user.activation_code
        url = "http://www.uncharted.net/account/reset_password/#{password}" 
        begin
          Emailer.deliver_reset_password(@user.email,password,url)	   
        end
        @message = "New password hasbeen mailed to #{@user.email}. Please check your mail and login."
        render :action => 'reset_password' and return
    else
        flash[:unreg_email] = 'Unregestered Email'
        render :action => 'forgot_password' and return
    end
  end
  
end
  
  
  
 # method to change password 
def change_password  
@page_title = "Change Password" 
if session[:user_screenname] == params[:id]
     if request.post?
        @user = User.find(session[:user_id])
         if current_user = User.authenticate(@user.email,params[:old_password])
              if (params[:password] == params[:password_confirmation])
                  current_user.password_hash = encrypted_password(params[:password] , current_user.password_salt)  
                    if current_user.save
                                 begin  
                                 Emailer.deliver_change_password(@user.email,params[:password]) 
                                 end
                                @message = "Your password has been changed.<br/> New password has sent to your email."  
                            else         
                                flash[:notice] = "Unable to change your password" 
                            end      
                    else
                      flash[:notice] = "password mismatch" 
                      @old_password = params[:old_password]
                    end      
            else
                flash[:notice] = "Incorrect old password" 
          end
        end
  else
   redirect_to profile_url(:id => session[:user_screenname]) and return
  end
  render :layout => 'home'
end
  
# method to edir user profile
def edit
  @page_title = "Account edit" 
    begin   
      @user = User.find(session[:user_id])  unless session[:user_id].blank?
      @profile = @user.profile
      rescue
      flash[:notice] = 'Some thing went wrong!!'
      render :template => 'shared/error'and return
    end
  render :layout => 'home'
end



# method to update user account details
def update  
   @page_title = "Account edit"   
    if request.post?  
                @user = User.find(session[:user_id])  unless session[:user_id].blank?
                @profile = @user.profile  
                address = Country.get_alt_longt(params[:user][:city],params[:user][:country_id])   
                if  address == nil
                      flash[:notice] = "unknown city for the selected country"
                       render :action => 'edit'and return
                else
                      @user.lat = address.latitude
                      @user.longt = address.longitude        
              end   
          # Why I'm here parameters          
          Add_explored_places(@profile,params[:reason_for_here],'why i am here')  
          @user.attributes = params[:user]  
          #@user.wanttoplace.update
         # @user.user_setting.update_attributes(params[:user_setting])  
          @user.profile.update_attributes(params[:profile]) 
          if @user.save
            session[:user_id] = @user.id
            session[:user_screenname] = @user.screen_name.gsub(' ', '_')
            flash[:notice] = 'User profile was successfully updated.'
            redirect_to :action => 'edit' and return     
          else
            flash[:notice] = 'Unable to update user details.'
            render :action => 'edit' and return     
          end  
   else
     redirect_to :action => 'edit' and return    
  end  
    render :layout => 'home'      
end

# method to update exploredplaces
def update_exploredplaces
 @user = User.find(session[:user_id])  unless session[:user_id].blank?
 Add_explored_places(@user.profile,params[:exploredplaces_list],'exploredplaces_list')
  flash[:notice] = "User Explored places was successfully updated."
  redirect_to :action => 'edit'
end

# method to update explorertype
def update_explorertype
  @user = User.find(session[:user_id])  unless session[:user_id].blank?
  Add_explored_places(@user.profile,params[:explorer_list],'explorer_list')
  flash[:notice] = "User Explorer type details was successfully updated."
  redirect_to :action => 'edit'
end  

# method to edit user profile photo
def change_photo
   @page_title = "Edit profile image" 
   @user = User.find(session[:user_id])  unless session[:user_id].blank?
   @profile = @user.profile  
       if request.post?      
          if @profile.update_attributes(params[:profile])  
          flash[:notice] = 'Profile image was successfully updated.'
          redirect_to :action => 'edit'and return
          else
          flash[:notice] = 'Unable to upload the profile image.'
          render :action => 'change_photo'and return
          end  
        end 
   render :layout => 'home'     
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return     

end
    

 
# method to activate new password
def reset_password  
  @page_title = "Password Reset"
  active = User.find_by_activation_code(params[:id])
  if active
      active.password_hash = encrypted_password(params[:id] ,active.password_salt) 
       if active.save
        flash[:login_falied] = "Please login"         
        @message = "Seccessfully activated your account with new password! you can login with your new password."
        else
        @message = "Unauthorized Request!"  
        end       
  else
       @message = "Invalid Account"      
  end       
    render :action => 'password_reset'
end
    
    
# method to signout user
def signout
  session[:user] = nil
  session[:user_id] = nil
  session[:user_screenname] = nil
  flash[:notice] = "You have successfully signed out"
  redirect_to :action=>:index    
end  

  
def flagged_content    
   if request.post?
      @flaged = FlagedContent.new(params[:flaged])
       @flaged.save!       
      @message = "Your message have been sent"
   else
       @flaged = FlagedContent.new  
    end

render :layout => false     
end  


#method to choose photoset
def choose_photoset
@photos = Photo.find(:all, :conditions => ["photoset_id LIKE ?", params[:photoset]])  
render :layout => false
end 

#method to choose videoset
def choose_videoset
@videos = Video.find(:all, :conditions => ["videoset_id LIKE ?", params[:videoset]])  
render :layout => false
end 

def encrypted_password(password,salt)
    string_to_hash = password + "unchatted" + salt 
		Digest::SHA1.hexdigest(string_to_hash)
end
 
private
  
# private method for explorer list  
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
