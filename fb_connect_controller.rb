class FbConnectController < ApplicationController



  def authenticate
    set_facebook_session 
    @facebook_session = Facebooker::Session.create('ratnam_rcv@yahoo.co.in', '%indian%')
    logger.debug "facebook session in authenticate: #{facebook_session.inspect}"
if !User.find_by_fb_user(facebook_user.uid)
 
 	 @user =  User.create(
	:id => facebook_user.uid,
	:first_name => facebook_user.first_name,
	:last_name => facebook_user.last_name,
	:username => facebook_user.name,
	:gender => facebook_user.sex,
	:password=> facebook_user.first_name,
	:hashed_password=>facebook_user.first_name,
	:email=>facebook_user.proxied_email, 
	:activated =>1,
	:fb_user =>facebook_user.uid,
	:fb_image=>facebook_user.pic
	#:city=> facebook_user.current_location,
	#:occupation=>facebook_user.first_name,
	#:birth_date=>facebook_user.birthday_date
	)

  face_user = User.find_by_fb_user(facebook_user.uid)
  
#render :text => params.inspect and return
  UserSetting.create(
	:user_id => face_user.id
	)

end
 
 session[:user_user_id] = facebook_user.uid
 redirect_to profile_url(:id =>facebook_user.name)
  #redirect_to @facebook_session.login_url
  end


  def connect

    begin
      secure_with_token!
      session[:facebook_session] = @facebook_session
 
      logger.debug "facebook session in connect: #{facebook_session.inspect}"

      if facebook_user
        if user = User.find_by_fb_uid(facebook_user.uid)
          login_user(user)

          return redirect_to('/')
        end

        # not a linked user, try to match a user record by email_hash
        facebook_user.email_hashes.each do |hash|
          if user = User.find_by_email_hash(hash)
            user.update_attribute(:fb_uid, facebook_user.uid)
            login_user(user)
            return redirect_to('/')
          end
        end
        
        # joining facebook user, send to fill in username/email
        return redirect_to(:controller => 'login', :action => 'register', :fb_user => 1)
      end

    # facebook quite often craps out and gives us no data
    rescue Curl::Err::GotNothingError => e
      return redirect_to(:action => 'authenticate')

    # it seems sometimes facebook gives us a useless auth token, so retry
    rescue Facebooker::Session::MissingOrInvalidParameter => e
      return redirect_to(:action => 'authenticate')
    end

    render(:nothing => true)
  end

 


  # callbacks, no session
  def post_authorize
    if linked_account_ids = params[:fb_sig_linked_account_ids].to_s.gsub(/\[|\]/,'').split(',')
      linked_account_ids.each do |user_user_id|
        if user = User.find_by_fb_user(user_user_id)
          user.update_attribute(:fb_uid, params[:fb_sig_user])
        end
      end
    end

    render :nothing => true
  end
end
