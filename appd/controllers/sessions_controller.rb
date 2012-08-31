# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  skip_before_filter :verify_authenticity_token, [:only=>:create]
  before_filter :ensure_secure

  protect_from_forgery :except => :albatross_login
    
  # render new.rhtml
  def new
    return redirect_for_login if logged_in?

		render :action => 'new', :layout => "login"
  end
  
  def show
    redirect_to new_session_path
  end

  def create
    begin
      self.current_user = Account.authenticate(params[:username], params[:password])
    rescue BlacklistedException
        return blacklisted_user_redirect
    end

    if logged_in?
      successful_auth
      
      redirect_for_login false
      
    else
      flash.now[:error] = "That was an incorrect username or password."
      
      render :action => 'new', :layout => 'login'
      
    end
  end

  def albatross_login
    self.current_user = Account.authenticate_with_tmp_password(params[:username], params[:password])
    if logged_in?
      successful_auth

      redirect_to account_path
    else
      flash.now[:error] = "Albatross login failed."
      
      render :action => 'new', :layout => 'login'
    end
  end

  def new_tmp_password
    render :action => 'new_tmp_password', :layout => 'login'
  end
  
  
  def send_tmp_password
    account = nil
    if params[:email] and !params[:email].empty?
      account = Account.find_by_email(params[:email])
    end
    
    if !account
      flash.now[:error] = "Please put in a valid email."
      render :action => 'new_tmp_password', :layout => 'login'
    else
      account.reset_password = Account.generate_random_password
      account.reset_password_expires_at = 24.hours.from_now

      if account.save
        Notifier.reset_password(account).deliver
        flash.now[:notice] = "A temporary reset password link has been sent to your email."
      else
        logger.error("Error sending password: #{account.errors.full_messages.to_sentence}")
        flash.now[:notice] = "Error sending password."
      end
      render :action => 'send_tmp_password', :layout => 'login'
    end
  end

  def reset_password
    account = Account.where("reset_password = ? and reset_password_expires_at > ?", params[:tmp_password], 24.hours.ago).first

    if account
      self.current_user = account

      successful_auth

      render :action => 'reset_password', :layout => 'login'
    else
      render :action => 'reset_failed', :layout => 'login'
    end
  end

  def change_password
    account = current_user

    if account.update_attributes(:password => params[:password], :reset_password => nil)
      redirect_for_login(false)
    else
      flash.now[:error] = "That password was invalid. Please try again."

      render :action => 'reset_password', :layout => 'login'
    end
  end
  
  def destroy
    # the message will be destroyed in the next steps, might want to keep it
    pass_flash = flash[:notice] if flash[:notice]
    
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    
    # We don't really want this because the front page is static, and it can get cached with it...
    flash[:notice] = pass_flash if pass_flash
    
    redirect_back_or_default(root_path)
  end
  
  private
  
  
	def redirect_to_change_password
		flash[:notice] = COPY['password_not_set_message']
		session[:return_to] = keywords_path
		redirect_to '/account'
	end

  def redirect_for_login(redir_to_pass = false)
    return redirect_to(new_plan_path(:plan => params[:plan])) unless params[:plan].blank?
    return redirect_to_change_password if redir_to_pass

    redirect_back_or_default keywords_path
  end

  def successful_auth
      last_login = current_user.logged_in_at
      session[:show_announcements_since] = last_login.to_s
      current_user.logged_in_at = Time.current
      current_user.tmp_password = nil
      
      current_user.remember_me # this saves logged_in_at and tmp_password
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }

      set_user_time_zone
	  	session[:show_did_you_know] = true
  end
  
end
