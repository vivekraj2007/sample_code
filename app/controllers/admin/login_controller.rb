class Admin::LoginController < ApplicationController
  
   before_filter :authorize_admin, :except =>[:index , :login]
  
  layout "admin"
  
  def index
    render :layout => false
  end 
  
  
  def list
    @admin = Admin.find(:all)
  end 
  
  def new
 @admin = Admin.new
  end
  
  
def change_password
    return unless request.post?
    if current_user = Admin.authenticate(session[:adminemail], params[:old_password])
      
      if (params[:password] == params[:password_confirmation])
        current_user.password = Digest::SHA1.hexdigest(params[:password]+"unchatted" )
        current_user.confirmation_password = current_user.password 
        
        flash[:notice] = current_user.save ?
              "Password changed" :
              "Password not changed" 
	redirect_to :action => 'list'
      else
        flash[:notice] = "Password mismatch" 
        @old_password = params[:old_password]
      end
    else
      flash[:notice] = "Wrong password" 
    end
    
  end
  
  def create
    @admin = Admin.new(params[:admin])
   
    if @admin.save
      flash[:notice] = " Admin Is Successfully Created"
        redirect_to :controller => "admin/login" , :action => "list"
    else
      flash[:notice] = "Unable to create Admin , try again"
      redirect_to :controller => "admin/login" , :action => "new"
      end
    end
  
  def login
   #~ if request.post?
      begin
        @admin = Admin.authenticate(params[:admin][:email], params[:admin][:password])
        session[:admin] = @admin.id
        session[:adminemail] = @admin.email
        @admin.update_attributes(:last_login => Time.now)
        flash[:notice] = " Welcome to unchatted"
        redirect_to :controller => "admin/login" , :action => "list"
       
      rescue
      flash[:warning] = "There was a problem logging you in. Please check your username and password and try again."
        render  :action => "index", :layout =>  false
      end
    #~ end
  end
  
  def myaccount
    @admin = Admin.find(session[:admin])
  end
  
  def logout
 @admin = Admin.find(session[:admin])
   session[:admin] = nil 
   flash[:notice] = "You have been logged out"
   redirect_to :action => "index"
  end

end
