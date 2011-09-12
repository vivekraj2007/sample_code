class LoginController < ApplicationController
  
    def index
    if request.post?
     session[:user] = User.authenticate(params[:email], params[:password])
    if session[:user]      
     flash[:notice] ="welcome"
     redirect_to :controller => '/share/events',:action => 'index'
    else
      flash[:notice] ="Invalid login details"
      render :action=>'index'
    end
    end
  end
  
  
end
