require 'net/http'

class TatangoController < ApplicationController
  before_filter :ensure_secure, :only => [:free_trial, :free_trial_2, :free_trial_3]

  def free_trial
    if (params[:geo].nil? or params[:geo] != "false") and ![0,225].include?(GeoIP.new("db/GeoIP.dat").country(request.remote_ip).country_code) and Rails.env.production?
      redirect_to :controller => :signup, :action => :signup_usonly
    else
      @account = Account.new
      @account.source = 'squeeze'
    end
  end
  
  def free_trial_2
    if (params[:geo].nil? or params[:geo] != "false") and ![0,225].include?(GeoIP.new("db/GeoIP.dat").country(request.remote_ip).country_code) and Rails.env.production?
      redirect_to :controller => :signup, :action => :signup_usonly
    else
      @account = Account.new
      @account.source = 'squeeze2'
    end
  end

  class EnterpriseContactSalesforce < Struct.new(:params)
    def perform
      lead_params = [:type, 'lead']
      lead_params += [:firstname, params[:firstname]]
      lead_params += [:lastname, params[:lastname]]
      lead_params += [:email, params[:email]]
      lead_params += [:office_number__c, PhoneNumber.new(params[:phone]).to_s]
      lead_params += [:company, params[:business]]
      lead_params += [:learn_more_request__c, params[:subject]]
      lead_params += [:traffic_keywords__c, (Account.traffic_keywords(utmz) rescue "")]
      lead_params += [:traffic_source__c, (Account.traffic_source(utmz) rescue "")]
      lead_params += [:ppc_traffic__c, ((!(Account.traffic_source(utmz) =~ /^PPC/).nil?).to_s rescue "false")]
      lead_params += [:non_ppc_traffic__c, ((Account.traffic_source(utmz) =~ /^PPC/).nil?.to_s rescue "true")]
      lead_params += [:tatangoplus__c, "true"]

      result = $salesforce.create :sObject => lead_params

      task_params = [:type, 'task']
      task_params += [:ownerid, '005U0000000M3m1IAC']
      task_params += [:whoid, result[:createResponse][:result][:id]]
      task_params += [:subject, 'Contact Form']
      task_params += [:status, 'Not Started']
      task_params += [:description, params[:textbox]]

      result = $salesforce.create :sObject => task_params
    end
  end
  
  def submit_enterprise_contact
    utmz = request.cookies["__utmz"]

    Delayed::Job.enqueue(EnterpriseContactSalesforce.new(params))

    redirect_to contact_us_message_sent_path
  end

  def submit_contact
    if !(params[:subject].blank? or params[:email].blank? or !PhoneNumber.new(params[:phone]).valid? or params[:fullname].blank? or params[:textbox].blank?)
      @success = ContactMailer.contact_message(params[:subject], params[:email], params[:phone], params[:business], params[:fullname], params[:textbox]).deliver
     
      if params[:nwsltr] == "on"
        first_name = params[:fullname].gsub(/ .*/, '')
        last_name = params[:fullname].gsub(/#{first_name} */, '')
        phone = params[:phone]
        Thread.new(first_name, last_name, phone, params[:email]) do |first_name, last_name, phone, email|
          begin
            $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['newsletter'], :email_address => email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'PHONE' => params[:phone]})
          rescue => e
            logger.error("#{e.inspect}\n#{e.backtrace.inspect}")
          end
        end
      end
    else
      @success = false
    end
  end

  def trial_autoresponder
    render :layout => false
  end

  def plus33033
    render :layout => false
  end

  def plus33033_canada
    render :layout => false
  end

  def plus33733
    render :layout => false
  end

  def plus33733_canada
    render :layout => false
  end

  def plus77411
    render :layout => false
  end

  def plus72468
    render :layout => false
  end

  def plusprivacy_policy
    render :layout => false
  end
  
end
