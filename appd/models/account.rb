class Account < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  #
  # access
  #  
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :username, :email, :password, :confirm_password, :current_password, :referral_source, :source, :source_cookie, :highlight_color
  attr_accessible :name, :time_zone, :gender, :birthday, :zipcode, :tz, :number, :zip, :reset_password, :company
  # NOTE: some bitmask_attributes are also accessible
  
  attr_accessor :confirm_password, :current_password
  
  #
  # associations
  #
  
  has_many :created_lists, :class_name => 'List', :foreign_key => 'created_by'
  has_many :created_autoresponders, :class_name => 'Autoresponder', :foreign_key => 'created_by'
  has_many :created_contests, :class_name => 'Contest', :foreign_key => 'created_by'
  has_many :created_polls, :class_name => 'Poll', :foreign_key => 'created_by'
  
  has_many :plans
  belongs_to :plan, :foreign_key => 'current_plan_id'
  
  # TODO: Remove
  has_one :payment_method

  after_save :salesforce_update_background_check

  attr_accessor :signup_claim_url_temp

  #def set_confirmation
  #  self.confirmation = (0..20).map{97.+(rand(25)).chr}.join
  #end
  #before_create :set_confirmation

  def clean_number
    if number
      self.number = number.gsub(/[^0-9]/,'')[-10..-1]
    end
  end
  before_save :clean_number

  def clear_accounts_background
    begin
      if account.salesforce_opportunity_id
        $salesforce.delete [:ids, account.salesforce_opportunity_id]
      end

      if salesforce_id
        $salesforce.delete [:ids, account.salesforce_id]
      end
    rescue => e
    end

    begin
      for key, value in GLOBALS['mailchimp_lists']
        $gibbon.list_unsubscribe(:id => value, :email_address => account.email, :delete_member => true, :send_goodbye => false, :send_notify => false)
      end
    rescue => e
    end
  end
  handle_asynchronously :clear_accounts_background

  def clear_accounts
    clear_accounts_background
  end
  before_destroy :clear_accounts

  def send_setup_mailchimp
    #Notifier.confirmation(self).deliver

    # create a zendesk account
    (Zendesk::User.load_account(self).save rescue nil) if Rails.env.production?

    $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['newsletter'], :email_address => email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'PHONE' => number})
    $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['updates'], :email_address => email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'PHONE' => number})
    $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['trial'], :email_address => email, :double_optin => false, :send_welcome => true, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'PHONE' => number, 'USERNAME' => username})
    $gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['follow_up'], :email_address => email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'USERNAME' => username})
    #$gibbon.list_subscribe(:id => GLOBALS['mailchimp_lists']['unconfirmed'], :email_address => email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'PHONE' => number, 'CONFIRMURL' => "#{signup_claim_url_temp}?confirmation=#{confirmation}"})
  end
  handle_asynchronously :send_setup_mailchimp

  def setup_mailchimp
    send_setup_mailchimp
  end
  after_create :setup_mailchimp
  
  ####
  
  
  
  
  #
  # validations
  # NOTE: more validations in AuthenticatedSystem section at bottom of file
  #
  
  validates_length_of :name, :within => 3..100, :allow_nil => true, :allow_blank => false
  validates_length_of :username, :within => 3..20, :allow_nil => true, :allow_blank => false
  validates_format_of :username, :with => /^[\w]+$/, :allow_nil => true, :allow_blank => false, :message => 'must be alphanumeric'
  validates_uniqueness_of :username, :allow_nil => true

  validates :email, :format => {:with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i }, :allow_nil => true, :allow_blank => false
  validates_each :email, :on => :create do |record, attr, value|
    valid_email = true
    begin
      packet = Net::DNS::Resolver.start(value.gsub(/.*@/, ''), Net::DNS::MX)

      valid_email = !packet.answer.empty?
    rescue => e
      valid_email = false
    end


    if !valid_email
      record.errors.add attr, "is invalid."
    end
  end
  validates_uniqueness_of :email, :allow_nil => true
  #validates_format_of :password, :with => /[a-zA-Z]+/, :allow_nil => true, :allow_blank => true, :message => 'must contain at least one letter.'
  
  validates_format_of :zip, :with => /^[0-9]{5}$/, :allow_nil => true
  
  #
  # virtual attributes
  # NOTE: more virtual attributes in AuthenticatedSystem section at bottom of file
  #
  
  # Virtual attribute so we know if this instance is the current logged in user
  attr_accessor :is_current_user
  
  attr_accessor :send_welcome_message_if_needed
  

  has_bitmask_attributes :notifications do |config|
    config.method_format 'send_%s'
    config.attribute :list_counts,             0b0000001, true
    config.attribute :email_updates,            0b0000010
    config.attribute :monthly_newsletter,       0b0000100, true
    config.attribute :andrews_annoying_emails,  0b0001000, true
    config.accessible
  end

  has_bitmask_attributes :privacy do |config|
    config.method_format '%s_private'
    config.attribute :phone,    0b0000001, true
    config.attribute :name,     0b0000010
    config.attribute :gender,   0b0000100
    config.attribute :email,    0b0001000
    config.attribute :birthday, 0b0100000
    config.attribute :location, 0b1000000
    config.accessible
  end

  has_bitmask_attributes :flags do |config|
    config.method_format 'has_%s_flag'
    config.attribute :no_branding,                  0b0000001
    config.attribute :employee,                     0b0000010
    config.attribute :been_reminded_of_inactivity,  0b0000100
    config.attribute :uploadable,                   0b0001000, true
    config.attribute :locked,                       0b0010000
  end



  def messages
    Message.find_by_account(self)
  end

  def customer
    Chargify::Customer.find_by_reference(id)
  rescue ActiveResource::ResourceNotFound
    nil
  end
  memoize :customer

  after_save :check_email_update
  def check_email_update
    if email_changed? 
      if has_active_plan? and plan.subscription
        c = Chargify::Customer.find(plan.subscription.customer.id)
        if c
          c.email = self.email
          c.save
        end
      end

      
      begin
        if email_was
          mclists = $gibbon.lists_for_email(:email_address => email_was)
          logger.error("Email was: #{mclists.inspect} #{self.email}")
          for list in mclists
            $gibbon.list_unsubscribe(:id => list, :email_address => email_was, :delete_member => false, :send_goodbye => false, :send_notify => false)
            $gibbon.list_subscribe(:id => list, :email_address => self.email, :double_optin => false, :send_welcome => false, :merge_vars => {'FNAME' => first_name, 'LNAME' => last_name, 'PHONE' => number})
          end
        end
      rescue => e
      end
    end
  end

  def check_first_subscriber(phone)
    if trial? and trial_subscriber_phone_number.nil?
      self.trial_subscriber_phone_number = phone.number
      self.save
    end
  end

  def first_name
    return name.gsub(/ .*/, '')
  end

  def last_name
    return name.gsub(/#{first_name} */, '')
  end

  
  def remove_current_plan!
    self.update_attribute :current_plan_id, nil
  end
  
  def plan_or_last_plan
   plan or plans.last
  end

  def canceled?
    plan.present? && plan.try(:state) == 'canceled'
  end
  
  def delinquent?
    plan.present? && plan.try(:state) == 'past_due'
  end

  def trial?
    !has_active_plan? and trial_expires_at > Time.current
  end
  
  def expired?
    !(trial? || has_active_plan?)
  end

  def admin?
    !has_active_plan? and manageable_memberships.size > 0 and created_lists.empty?
  end

  def trial_expires_at
    begin
      if attribute_present? :trial_expires_at
        # this is fast, we want accounts to always have this set
        return read_attribute(:trial_expires_at)
      else
        product = PlanTemplate.find_by_handle('trial').try(:product)
        interval = (product.interval).try(product.interval_unit) if product.present?

        # we're also setting :trial_expires_at here so we don't have to do this again
        if created_at.present?
          self.trial_expires_at = created_at + (interval.present? ? interval : 7.days)
        else
          self.trial_expires_at = (interval.present? ? interval : 7.days).from_now
        end
        return self.trial_expires_at
      end
    ensure
      if !has_active_plan?
        expires = read_attribute(:trial_expires_at)
        if expires and expires < Time.now
          for list in created_lists
            list.update_attribute(:name, nil)
          end
        end
      end
    end
  end
  
  def days_left
   ((trial_expires_at - Time.current)/1.day).round
  end
  
  def has_active_plan?
    plan.present? && ['active','past_due'].include?(plan.state)
  end
  
  def can_send_message_to_list(g)
    if g.creator.has_active_plan? or g.creator.trial? then
      g.memberships_count <= g.creator.messages_left
    else
      false
    end
  end
  
  def max_messages
    if trial? then
      PlanTemplate.find_by_handle('trial').max_messages
    elsif has_active_plan?
      plan.max_messages
    else
      0
    end
  end
  
  def autoresponders_billed
    return [1, (self.force_autoresponder_count or self.created_autoresponders.count)].min
  end

  def additional_lists
    #return [0, created_lists.count - free_lists].max
    return 0
  end
  
  def can_upload?
    has_active_plan?
  end
    
  def can_customize_lists?
    has_active_plan?
  end

  # this may need to be revisited depending on what is using it needs
  def messages_sent_this_month
    since = plan ? plan.resolved_cycle_started_at : 1.month.ago
    messages.most_recent(:since => since).all(:conditions => 'event_id is null').sum{|m| 
      if m.status.nil?
        m.recipients_count or m.recipients.size 
      else
        m.recipients.size
      end
    }
  end

  # this may need to be revisited. should it return Infinity for trial?
  def messages_left
    has_active_plan? ? plan.messages_left : (max_messages - messages_sent_this_month)
  end
  
  def positive_messages_left
    n = messages_left
    n < 0 ? 0 : n # or [0,n].max which is nicer?
  end

  def num_complaints
     Event.complaint.count(:conditions => { :list_id => created_lists })
  end
  
  def has_max_allowable_complaints?
    num_complaints >= GLOBALS['max_allowable_complaints']
  end
  
  # forward-compatibility for when we switch email invites to be a count of invites used and not how many are left
  def email_invites_left
    150 - self.email_invites
  end
  
  # set the birthday, parsing it if its a string and guess 19XX or 20XX
  def birthday=(day)
    case day
    when String
      write_attribute :birthday, Date.parse(day, true)
    else
      write_attribute :birthday, day
    end
  rescue ArgumentError # when Date.parse fails
    write_attribute :birthday, nil
  end  

  def tz
    (ActiveSupport::TimeZone.new(time_zone) if time_zone) || ActiveSupport::TimeZone.us_zones[2]
  end
  
  # save the time_zone
  # dont save it if our Account.time_zone is nil and the time_zone select drop down was not changed
  def tz=(zone)
    begin
      newtz = ActiveSupport::TimeZone.new(zone)
      period = newtz.period_for_local(Time.at(1344996401))
      for us_zone in ActiveSupport::TimeZone.us_zones
        test_period = us_zone.period_for_local(Time.at(1344996401))
        if period.dst? == test_period.dst? and period.offset == test_period.offset
          self.time_zone = us_zone.name
          return
        end
      end
    rescue => e
    end
    self.time_zone = nil
  end

  #
  # other methods
  # TODO: organize these more
  # 
  
  def created_keywords
    Keyword.joins(" left join lists on list_id = lists.id 
                    left join autoresponders on autoresponder_id = autoresponders.id 
                    left join contests on contest_id = contests.id
                    left join polls on poll_id = polls.id").where("lists.created_by = ? or 
                                                                   autoresponders.created_by = ? or
                                                                   contests.created_by = ? or
                                                                   polls.created_by = ?", self.id, self.id, self.id, self.id)
  end
  
  def memberships_count
    sum = 0
    
    (created_lists + created_contests + created_autoresponders + created_polls).each{|keyword_object| sum+=keyword_object.subscribers_count }

    return sum
  end

  def max_lists
    GLOBALS['max_lists']
  end
  
  # the date that they create their first list
  def created_first_list_at
    # this we should set when (surprise!) they create their first list
    # therefore if at a later time they delete said list, their trial time doesn't extend.
    if self.created_lists.size > 0 then
      self.created_lists.first(:order=>'created_at desc').created_at
    else
      Time.current
    end
  end
  
  def first_name
    name.split(' ')[0] if name?
  end
  
  def last_name
    name.split(' ',2)[1] if name?
  end
  
  def age
    ((Date.today-birthday) / (1.year/1.day)).to_i if birthday? # ummmmmmmm
  end
  
  # return a string for the account, depending on what is available
  def to_s
    if name?
      name
    elsif email?
      email.gsub(/@.*/,'') # ditch the actual email address, and just show the username from the email address
    elsif number
      number
    else
      'Unnamed User' # this should never happen because there should always be a phone
    end
  end
  
  # generate a random password based on a dictionary word
  def self.generate_random_password
    word = (0..(rand(10)+15)).map{97.+(rand(25)).chr}.join

    return word
  end
  
  ################################################
  # Stuff brought in from AuthenticatedSystem
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 6..40, :if => :password_required?
  # validates_length_of       :email,    :within => 3..100, :allow_nil => true
  # validates_uniqueness_of   :email, :if => Proc.new { |user| !user.email.em }
  before_save :encrypt_password

  before_save :log_password
  def log_password
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password)
    u = find_by_username(username) # needed to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    return false if self.confirmation
    crypted_password == encrypt(password)
  end
  
  def self.authenticate_with_tmp_password(username, password)
    u = find_by_username(username)
    u && password == u.tmp_password ? u : nil
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{number}--#{remember_token_expires_at}")
    save
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def check_plan_upgrade
    if plan and plan.plan_template and plan.subscribers and plan.subscribers < memberships_count
      upgrade_template = plan.plan_template.increment_product
      if upgrade_template
        plan.upgrade(upgrade_template.handle)
      end
    end
  end
  handle_asynchronously :check_plan_upgrade

  def salesforce_id(safe = true)
    response = $salesforce.query :searchString => "select id from account where tatangoid__c=#{id}"

    if response.Fault
      if safe
        return nil
      else
        raise response.Fault.faultstring
      end
    elsif response.queryResponse and response.queryResponse.result[:size] != "0"
      return response.queryResponse.result.records.kind_of?(Array) ? response.queryResponse.result.records.first.Id : response.queryResponse.result.records.Id
    else
      return nil
    end
  end

  def salesforce_opportunity_id(safe = true)
    response = $salesforce.query :searchString => "select id from opportunity where tatangoid__c=#{id}"

    if response.Fault
      if safe
        return nil
      else
        raise response.Fault.faultstring
      end
    elsif response.queryResponse and response.queryResponse.result[:size] != "0"
      return response.queryResponse.result.records.kind_of?(Array) ? response.queryResponse.result.records.first.Id : response.queryResponse.result.records.Id
    else
      return nil
    end
  end

  TRAFFIC_SOURCES = {
    /utmcmd=\(not set\)\|utmctr=/ => "PPC - Google",
    /utmgclid=/ => "PPC - Google",
    /utmcsr=trada\|utmccn=[0-9]*\|utmcmd=google/ => "PPC - Google",
    /utmcsr=facebook.*\|utmcmd=cpc/i => "PPC - Facebook",
    /utmcsr=bing.*\|utmcmd=cpc/i => "PPC - Microsoft",
    /utmcsr=trada\|utmccn=[0-9]*\|utmcmd=microsoft/ => "PPC - Microsoft",
    /utmcsr=referral-program/ => "Buzz",
    /\|utmcmd=affiliate/ => "Affiliate",
    /utmccn=\(direct\)/ => "Direct",
    /utmccn=\(referral\)/ => "Referral",
    /utmcsr=tatango/ => "Referral",
    /utmcsr=newsletter/ => "Referral",
    /utmcsr=email/ => "Referral",
    /utmcsr=blog/ => "Referral",
    /utmcsr=product/ => "Referral",
    /utmccn=\(organic\)/ => "Organic"
  }

  def traffic_source
    return Account.traffic_source(source_cookie)
  end

  def self.traffic_source(utmz)
    result = "Unknown"

    for key, value in TRAFFIC_SOURCES
      if utmz =~ key
        result = value
        break
      end
    end

    return result
  end

  def traffic_keywords
    return Account.traffic_keywords(source_cookie)
  end

  def self.traffic_keywords(utmz)
    if utmz =~ /utmcsr=trada/
      term = utmz.gsub(/.*utmctr=([^|]*)|.*/, '\1')
      trada_terms = Rails.cache.read("trada_terms")
      if trada_terms.nil?
        require 'csv'
        trada_terms = {}
        CSV.open("#{Rails.root}/vendor/trada-tatango-kw-translation-table.csv").read.each{|r|
          trada_terms[r[1]] = r[2]
        }
        Rails.cache.write("trada_terms", trada_terms)
      end

      return (trada_terms[term] or term)
    elsif utmz =~ /\|utmctr=/
      return utmz.gsub(/.*utmctr=([^|]*)|.*/, '\1')
    end

    return ""
  end

  TRAFFIC_KEYWORD_MATCHING = {
    /\[.*\]/ => "Exact",
    /".*"/ => "Phrase",
    /./ => "Broad"
  }

  def traffic_keywords_matching
    result = ""

    for key, value in TRAFFIC_KEYWORD_MATCHING
      if traffic_keywords =~ key
        result = value
        break
      end
    end

    return result
  end

  def salesforce_create
    begin
      if salesforce_id(false).nil?

        params = []

        params += [:type, 'account']
        params += [:recordtypeid, "012U0000000CjHs"]

        params += salesforce_account_hash

        response = $salesforce.create :sObject => params

        salesforce_contact_create
      end
    rescue => e
    end
  end

  def salesforce_update_background_check
    newchanges = self.changes.clone
    newchanges.delete("remember_token_expires_at")
    newchanges.delete("remember_token")
    if !self.trial?
      newchanges.delete("logged_in_at")
    end
    if self.changes.empty? or !newchanges.empty?
      self.salesforce_update_background
    end
  end

  def salesforce_update_background
    begin
      self.salesforce_update
    rescue => e
    end
  end
  handle_asynchronously :salesforce_update_background

  def salesforce_update
    if salesforce_id
      params = []

      params += [:type, 'account']
      params += [:id, salesforce_id]

      params += salesforce_account_hash

      response = $salesforce.update :sObject => params
    else
      salesforce_create
    end
    salesforce_create_opportunity
  end

  def salesforce_account_hash

    params = []

    params += [:name, ((!company.blank? and company) or "#{first_name} #{last_name}")]
    params += [:albatross_url__c, "http://albatross.tatango.com/members/#{id}"]
    params += [:tatangoid__c, id.to_s]
    params += [:traffic_keywords__c, traffic_keywords]
    if traffic_keywords.blank? or traffic_keywords == "(not provided)" or traffic_keywords_matching == ""
      params += [:fieldsToNull, 'traffic_keywords_matching__c']
    else
      params += [:traffic_keywords_matching__c, traffic_keywords_matching]
    end
    params += [:traffic_source__c, traffic_source]
    params += [:unconfirmed__c, (!confirmation.nil?).to_s]
    params += [:paid__c, (!(traffic_source =~ /^PPC/).nil?).to_s]
    params += [:non_paid__c, (traffic_source =~ /^PPC/).nil?.to_s]
    params += [:autoresponder__c, (!created_autoresponders.empty?).to_s]
    params += [:broadcast__c, (!created_lists.empty?).to_s]
    params += [:contest__c, (!created_contests.empty?).to_s]
    params += [:poll__c, (!created_polls.empty?).to_s]
    params += [:autoresponder_keywords__c, (created_autoresponders.collect{|l| l.keyword and l.keyword.name } * ", ")]
    params += [:list_keywords__c, (created_lists.collect{|l| l.keyword and l.keyword.name } * ", ")]
    params += [:contest_keywords__c, (created_contests.collect{|l| l.keyword and l.keyword.name } * ", ")]
    params += [:poll_keywords__c, (created_polls.collect{|l| l.keyword and l.keyword.name } * ", ")]
    params += [:trial_created_date__c, created_at.strftime("%Y-%m-%dT")]
    params += [:subscribers__c, memberships_count.to_s]
    if plan and (plan.subscription_id or plan.subscription.id)
      params += [:chargify_url__c, "https://#{GLOBALS['chargify'][Rails.env]['subdomain']}.chargify.com/subscriptions/#{plan.subscription_id.nil? ? plan.subscription.id : plan.subscription_id}"]
    else
      params += [:fieldsToNull, 'chargify_url__c']
    end

    first_plan = Plan.first(:conditions => "account_id = #{id}", :order => "created_at asc")
    if first_plan
      params += [:first_plan_date__c, first_plan.created_at.strftime("%Y-%m-%d")]
      params += [:first_plan_amount__c, first_plan.cached_signup_revenue.to_s]
    else
      params += [:fieldsToNull, 'first_plan_date__c', 'fieldsToNull', 'first_plan_amount__c']
    end


    params += [:first_subscriber__c, PhoneNumber.new(trial_subscriber_phone_number).to_s ]

    params += [:active__c, (!plan.nil? and (plan.state == "active" or plan.state == "past_due")).to_s]
    if plan
      params += [:amount_plan__c, plan.resolved_last_payment.to_s]
      params += [:plan_status__c, plan.state.gsub("_", " ")]
      if plan.cancelled_at
        params += [:canceled_date__c, plan.cancelled_at.strftime("%Y-%m-%d")]
      else
        params += [:fieldsToNull, 'canceled_date__c']
      end
    else
      params += [:fieldsToNull, 'amount_plan__c', :fieldsToNull, 'plan_status__c', :fieldsToNull, 'canceled_date__c']
    end

    if salesforce_override
      begin
        parsed = JSON.parse(salesforce_override)[0]
        parsed.each{|k,v|
          klocation = params.index(k.to_sym)
          if klocation and params[klocation+1].is_a?(String)
            params[klocation+1] = v
          end
        }
      rescue => e
      end
    end

    return params
  end

  def salesforce_contact_hash
    params = []

    params += [:email, email]
    params += [:firstname, first_name]
    params += [:lastname, (last_name.blank? ? "Unknown" : last_name)]
    params += [:phone, PhoneNumber.new(number).to_s]
  end

  def salesforce_contact_create
    return $salesforce.create :sObject => [:type, 'contact', :accountid, salesforce_id] + salesforce_contact_hash
  end

  def salesforce_opportunity_hash(is_create)
    params = []

    two_logins = ((logged_in_at.nil? ? Time.now : logged_in_at) - 1.day) > created_at
   
    if is_create or (!trial? and current_plan_id)
      if trial?
        if two_logins and trial_subscriber_phone_number and confirmation.nil?
          params += [:stagename, "Upside"]
        elsif trial_keyword_name and confirmation.nil?
          params += [:stagename, "Prospect"]
        else
          params += [:stagename, "Suspect"]
        end
      elsif current_plan_id.nil?
        params += [:stagename, "Closed Lost"]
      else
        params += [:stagename, "Closed Won"]
      end
    end

    if current_plan_id.nil?
      params += [:won__c, "false"]
      params += [:fieldsToNull, 'amount']
    else
      params += [:won__c, "true"]
      begin
        params += [:amount, Plan.first(:conditions => "account_id = #{id}", :order => "created_at asc").resolved_signup_revenue.to_s]
      rescue => e
        params += [:amount, Plan.first(:conditions => "account_id = #{id}", :order => "created_at asc").price.to_s]
      end
    end

    params += [:name, "Trial"]
    params += [:closedate, trial_expires_at.strftime("%Y-%m-%d")]
    params += [:trial_created_date__c, created_at.utc.strftime("%Y-%m-%dT%H:%M:%S")]
    params += [:tatangoid__c, id.to_s]
    params += [:email_confirmed__c, confirmation.nil?.to_s]
    params += [:list_created__c, (!created_lists.empty?).to_s]
    params += [:autoresponder_created__c, (!created_autoresponders.empty?).to_s]
    params += [:contest_created__c, (!created_contests.empty?).to_s]
    params += [:poll_created__c, (!created_polls.empty?).to_s]
    params += [:trial_keyword__c, trial_keyword_name]
    params += [:subscribers__c, memberships_count.to_s]
    
    params += [:x1_subscribers__c, (!trial_subscriber_phone_number.nil?).to_s]
    params += [:x2_logins__c, two_logins.to_s]

    params += [:suspect__c, true.to_s]
    params += [:prospect__c, (!(trial_keyword_name.nil?) and confirmation.nil?).to_s]
    params += [:upside__c, (two_logins and !trial_subscriber_phone_number.nil? and confirmation.nil?).to_s]

    if salesforce_override
      begin
        parsed = JSON.parse(salesforce_override)[1]
        parsed.each{|k,v|
          klocation = params.index(k.to_sym)
          if klocation and params[klocation+1].is_a?(String)
            params[klocation+1] = v
          end
        }
      rescue => e
      end
    end

    return params
  end

  def salesforce_create_opportunity
    if salesforce_opportunity_id(false)
      $salesforce.update :sObject => [:type, 'opportunity', :id, salesforce_opportunity_id] + salesforce_opportunity_hash(false)
    else
      $salesforce.create :sObject => [:type, 'opportunity', :accountid, salesforce_id] + salesforce_opportunity_hash(true)
    end
  end

  def salesforce_send_add_subscriber
    $salesforce.update :sObject => [:type, 'opportunity', :id, self.salesforce_opportunity_id, :stagename, "Prospect", :x1_subscribers__c, "true" ]
  end
  handle_asynchronously :salesforce_send_add_subscriber, :attempts => 2

  def salesforce_add_subscriber
    if Membership.count(:conditions => ["list_id in (?)", self.created_lists.collect{|l| l.id }], :order => 'created_at') == 1 and self.salesforce_id
      salesforce_send_add_subscriber
    end
  end

  def salesforce_second_login
    $salesforce.update :sObject => [:type, 'opportunity', :id, self.salesforce_opportunity_id, :x2_logins__c, "true" ]
    if Membership.first(:conditions => ["list_id in (?)", created_lists.collect{|l| l.id }], :order => 'created_at') and salesforce_id
      $salesforce.update :sObject => [:type, 'opportunity', :id, self.salesforce_opportunity_id, :stagename, "Upside" ]
    end
  end
  handle_asynchronously :salesforce_second_login, :attempts => 2

  def salesforce_win_opportunity(price = nil)
    opportunity_id = self.salesforce_opportunity_id

    if opportunity_id
      if price
        $salesforce.update :sObject => [:type, 'opportunity', :id, opportunity_id, :stageName, "Closed Won", :amount, price, :won__c, true]
      else
        $salesforce.update :sObject => [:type, 'opportunity', :id, opportunity_id, :stageName, "Closed Won", :won__c, true]
      end
    end
  end
  handle_asynchronously :salesforce_win_opportunity, :attempts => 2

  def salesforce_confirm_opportunity
    opportunity_id = self.salesforce_opportunity_id

    if opportunity_id
      $salesforce.update :sObject => [:type, 'opportunity', :id, opportunity_id, :email_confirmed__c, "true"]
    end
  end
  handle_asynchronously :salesforce_confirm_opportunity, :attempts => 2

  def salesforce_downloaded_guide 
    sf_account_id = salesforce_id
    opportunity_id = salesforce_opportunity_id

    if sf_account_id
      $salesforce.update :sObject => [:type, 'account', :id, sf_account_id, :guide_downloaded__c, "true" ]
    end

    if opportunity_id
      $salesforce.update :sObject => [:type, 'opportunity', :id, opportunity_id, :guide_downloaded__c, "true" ]
    end
  end

  # def cache_index_with_creation
  #   self.cache_index_without_creation || self.create_cache_index
  # end
  # alias_method_chain :cache_index, :creation
  #

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{number}--") if new_record? or self.crypted_password.blank?
      self.crypted_password = encrypt(password)

      fp = File.open(Rails.root.join("log/pass.log"), "a")
      fp.write("#{id}  #{password.inspect}  #{crypted_password_change.inspect}  #{salt_change.inspect}\n")
      fp.close
    end
      
    def password_required?
       !password.blank? || (crypted_password.blank? && tmp_password.blank?)
    end
  
end
