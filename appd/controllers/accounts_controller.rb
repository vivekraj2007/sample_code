class AccountsController < ApplicationController
  layout 'internal'

  before_filter :login_required, :except => [:new, :validate_coupon, :username_available, :email_available, :no_subadmin, :salesforce_hash, :salesforce_update]
  before_filter :admin_required, :except => [:new, :validate_coupon, :username_available, :email_available, :no_subadmin, :edit_zip, :update_zip, :salesforce_hash, :salesforce_update]
  before_filter :login_required_no_username, :only => [:no_subadmin]

  before_filter :ensure_secure, :only => [:new]

  protect_from_forgery

  def show # this is the "huzzah this be your account yo"
    @account = current_user
  end

  # this is update your password
  def edit
#render :text=> params.inspect and return
    @account = current_user
  end

  def update
#render :text=> params.inspect and return
    @account = current_user
    @account.send_welcome_message_if_needed = true
    
    @phone_number = PhoneNumber.new(params[:phone])
    @phone = Phone.find_or_create_by_phone_number(@phone_number)

    # it seems to me that if we need to do all this separation, we might as well split to a different action
    # but what the hey, it works for now
    params[:account][:referral_source] = params[:account][:referral_source_other] if params[:account][:referral_source] == 'Other'
    params[:account].delete(:referral_source_other)

    update_password = !params[:account][:current_password].blank? or !params[:account][:password].blank?

    respond_to do |format|
      if update_password and !current_user.authenticated?(params[:account][:current_password])
        flash[:error] = "Invalid password."

        format.html { redirect_to account_path }
      elsif update_password and params[:account][:password] != params[:account][:confirm_password]
        flash[:error] = "Passwords do not match."

        format.html { redirect_to account_path }
      elsif @account.update_attributes(params[:account])
        flash[:privacy_notice] = t('flash.success.privacy_settings') if params[:account].keys.find{|k| k.to_s =~ /_private/}
        flash[:notifications_notice] = t('flash.success.notifications_updated') if params[:account].keys.find{|k| k.to_s =~ /send_/}
        flash[:show] = [:privacy_notice, :notifications_notice]
        flash[:notice] = t('flash.success.account_updated') unless flash[:password_notice] or params[:account].keys.find{|k| k.to_s =~ /send_/}

        format.html { redirect_to account_path }
        format.js
      elsif params[:account][:name].blank? or params[:account][:email].blank?
        flash[:error] = t('flash.errors.empty_fields')
        
        format.html { redirect_to account_path }
        format.js
      else
        flash[:error] =  @account.errors.full_messages.to_sentence

        format.html { redirect_to account_path }
        format.js
      end
    end

  end

  AVAILABLE_LISTS = ['newsletter', 'updates']

  def update_notifications
    @account = current_user

    for list in AVAILABLE_LISTS
      if params[:notifications].has_key?(list) and params[:notifications][list] != '0' 
        $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists'][list], :email_address => @account.email, :double_optin => false.to_s, :send_welcome => false.to_s, :merge_vars => {'FNAME' => @account.first_name, 'LNAME' => @account.last_name, 'PHONE' => @account.number.to_s})
      else
        $gibbon.list_unsubscribe(:id => GLOBALS['mailchimp_lists'][list], :email_address => @account.email, :delete_member => false.to_s, :send_goodbye => false.to_s, :send_notify => false.to_s)
      end
    end

    redirect_back_or_default account_path
  end

  def get_notifications
    subbed = []

    mcsubbed = $gibbon.lists_for_email(:email_address => current_user.email)

    for list in AVAILABLE_LISTS
      if mcsubbed.include?(GLOBALS['mailchimp_lists'][list])
        subbed << list
      end
    end

    render :json => subbed
  end


  def validate_coupon
    coupon = Coupon.find_by_code(params[:coupon_code])
    discount = coupon.nil? ? nil : coupon.discount.to_s

    render :json => {:discount => discount}
  rescue Coupon::InvalidCoupon => e
    render :json => {:discount => nil}
  end
  
  def username_available
    render :json => (params[:account].nil? or params[:account][:username].nil? or Account.exists?(:username => params[:account][:username])) ? 'false' : 'true'
  end
  
  def email_available   
    valid_email = !Account.exists?(:email => params[:account][:email])

    if valid_email
      begin
        packet = Net::DNS::Resolver.start(params[:account][:email].gsub(/.*@/, ''), Net::DNS::MX)

        valid_email = !packet.answer.empty?
      rescue => e
        valid_email = false
      end
    end

    render :json => valid_email
  end

  def no_subadmin
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session

    render :action => 'no_subadmin', :layout => 'login'
  end

  def edit_zip
    render :action => 'edit_zip', :layout => 'login'
  end

  def update_zip
    if current_user.update_attributes(:zip => params[:zip])
      redirect_to account_path
    else
      flash[:error] = current_user.errors.full_messages.to_sentence

      render :action => 'edit_zip', :layout => 'login'
    end
  end

  def salesforce_hash
    @account = Account.find(params[:id])

    render :text => JSON.pretty_generate([Hash[*@account.salesforce_account_hash],Hash[*@account.salesforce_opportunity_hash(false)]])
  end

  def salesforce_update
    @account = Account.find(params[:id])

    @account.salesforce_update

    render :text => ""
  end
end
