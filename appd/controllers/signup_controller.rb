require 'geoip'

class SignupController < ApplicationController
  before_filter :ensure_secure

  def signup
    if logged_in?
      redirect_to keywords_path
    else
      if (params[:geo].nil? or params[:geo] != "false") and ![0,225].include?(GeoIP.new("db/GeoIP.dat").country(request.remote_ip).country_code) and Rails.env.production?
        redirect_to :action => :signup_usonly
      else
        @account = Account.new
        @account.source = 'normal'
      end
    end
  end

  def signup_confirm
    @account = Account.find_by_email(params[:account][:email])

    if @account.nil? or @account.confirmation.nil?
      @account = Account.new(params[:account])
    elsif @account
      @account.update_attributes(params[:account])
    end
  
    # existing phone numbers are not valid
    if @account.valid? then
      Account.transaction do
        @account.trial_expires_at = Time.now + (GLOBALS['trial_days']).days # will try to set it from chargify
        @account.logged_in_at = Time.current
        if request.cookies.has_key?("__utmz")
          @account.source_cookie = request.cookies["__utmz"]
        end
        @account.signup_claim_url_temp = signup_claim_url
        @account.save

      end
      flash[:error] = nil
      self.current_user = @account

      flash[:created_trial] = true
      redirect_to (keywords_url(:created_trial => "true"))
    else
      # TODO: Need nicer error messages, combine validations with javascript
      flash[:error] = 'There are errors in the provided information! ' + @account.errors.full_messages.to_sentence
      render :signup
    end
  end

  def signup_claim 
    @account = Account.find_by_confirmation(params[:confirmation])

    if @account
      @account.confirmation = nil
      @account.save
      self.current_user = @account
        
      thread = Thread.new(@account) do |account|
        $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['trial'], :email_address => account.email, :double_optin => false, :send_welcome => true, :merge_vars => {'FNAME' => account.first_name, 'LNAME' => account.last_name, 'PHONE' => account.number, 'USERNAME' => account.username})
        $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['follow_up'], :email_address => account.email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => account.first_name, 'LNAME' => account.last_name, 'USERNAME' => account.username})
        $gibbon.list_unsubscribe(:id => GLOBALS['mailchimp_lists']['unconfirmed'], :email_address => account.email, :send_goodbye => false, :delete_member => true, :send_goodbye => false, :send_notify => false)
      end
          
      @account.salesforce_confirm_opportunity

      flash[:created_trial] = true
      redirect_to (keywords_url(:created_trial => "true"))
    else
      redirect_to login_path
    end
  end
end
