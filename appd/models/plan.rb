class Plan < ActiveRecord::Base
  include PlanTemplate::SharedAttributeStuff
  
  before_create :copy_plan_template

  belongs_to :account
  has_one :active_account, :foreign_key => 'current_plan_id', :class_name => 'Account'
  belongs_to :plan_template

  # this was has_one, which read more nicely here, but didn't make sense on the data level
  # switched to belongs_to on 2009-08-19 at about 16:34 PDT
  belongs_to :previous_plan, :foreign_key => 'prev_plan_id', :class_name => 'Plan'

  has_many :credits


  scope :active, joins(:active_account).readonly(false)
  scope :need_reconciliation, lambda {
    where('cycle_at <= ?', Time.current)
  }

  # we never want a plan without an account
  validates_presence_of :account

  attr_reader :credit_card
  attr_writer :subscription
  attr_accessor :coupon_code


  def upgrade(handle, local_only = false)
    unless local_only
      subscription.product_handle = handle
      response = subscription.save
      # chargify returns subscription data, convert it to hash
      sub = Hash.from_xml(response.body)['subscription'] rescue {}
      # load activeresource object from a hash
      subscription.load(sub)
      # force reload if couldn't get data from the hash
      subscription(true) if sub.blank?
    end

    unless self.handle == handle
      self.plan_template = PlanTemplate.find_by_handle handle
      copy_plan_template
    end

    self.cycle_started_at = subscription.current_period_started_at
    self.cycle_at = subscription.current_period_ends_at
    self.state = subscription.state
    self.save

  rescue ActiveResource::ResourceInvalid
    subscription.errors.full_messages.each{|err| errors[:base] << (err)}
    false
  end

  def self.reconcile! subscription_ids
    subscription_ids.each do |id|

      begin
        sub = Chargify::Subscription.find(id)
        acc = Account.find sub.customer.reference.to_i

        if (acc.plan.nil?)
          # this shouldn't ever happen... and let's hope it's not custom!
          logger.warn("Well crap, can't find a plan for ##{id}... creating")
          plan = acc.plans.build :plan_template => PlanTemplate.find_by_handle(sub.product.handle)
          if plan.save
            acc.update_attribute(:plan, plan)
          else
            logger.error("Couldn't find or recreate a plan for ##{id}!")
          end
        else
          plan = acc.plan
          plan.upgrade(sub.product.handle, true)
        end

        if plan.state == 'canceled'
          plan.cancel!(sub.canceled_at)
        elsif plan.cancelled?
          plan.uncancel!
        end

        if ['active', 'past_due'].include?(plan.state)
          plan.update_attribute(:state, plan.state)
        end

        logger.debug("Changed plan ##{plan.id} state to #{plan.state} from postback.")
      rescue ActiveResource::ResourceNotFound
        logger.warn("Couldn't find subscription ##{id} from postback.")
      end

    end
  end
  
  def is_from_template?(in_plan_template = nil)
    if in_plan_template.nil?
      plan_template_id?
    else
      in_plan_template.id == plan_template_id
    end
  end
  
  def name
    is_from_template? ? plan_template.name : 'Custom'
  end
  def subtitle
    is_from_template? ? plan_template.subtitle : I18n.t(:'plan.custom_subtitle')
  end
  
  def handle
    is_from_template? ? plan_template.handle : 'custom'
  end

  def is_active?
    !!active_account
  end
  
  def cancelled?
    cancelled_at?
  end

  def cancel!(cancel_date = nil)
    if cancel_date
      update_attribute :cancelled_at, cancel_date
    else
      update_attribute :cancelled_at, Time.current
    end
    
    account.update_attribute :trial_expires_at, Time.current
  end
  
  def uncancel!
    upgrade(handle, true) # will update state and dates
    update_attribute :cancelled_at, nil
  end

  def state(force_update = false)
    if read_attribute(:state).blank? or force_update
      self.reload # force subscription to reload
      update_attribute :state, subscription.try(:state)
    end
    read_attribute(:state)
  end
  
  # % of time left until the next cycle period, used for proration
  def percent_until_cycle_end
    100-(Time.current - resolved_cycle_started_at)*100/(resolved_cycle_at - resolved_cycle_started_at)
  end

  def prorated_price target_plan
    (target_plan.price-self.price)*percent_until_cycle_end/100
  end

  def product
    subscription.try(:product)
  end

  def subscription(force_update = false)
    if @subscription.nil? or force_update
      @subscription = subscription_id.nil? ? Chargify::Subscription.find_by_customer_reference(account_id) : Chargify::Subscription.find(subscription_id)
    end
    return @subscription
  rescue SocketError
    logger.error("Can't connect to the network to get a subscription")
    nil
  rescue ActiveResource::ResourceNotFound
    nil
  end

  def coupon_discount_percent
    @@coupon_percents ||= {}

    if !@@coupon_percents.has_key?("#{subscription.product.product_family.id},#{subscription.coupon_code}")
      @@coupon_percents["#{subscription.product.product_family.id},#{subscription.coupon_code}"] = begin
        Chargify::Coupon.find_by_product_family_id_and_code(subscription.product.product_family.id, subscription.coupon_code).percentage
      rescue SocketError
        0
      rescue ActiveResource::ResourceNotFound
        0
      end
    end

    return @@coupon_percents["#{subscription.product.product_family.id},#{subscription.coupon_code}"]
  end

  attr_accessor :looping

  def resolved_cycle_started_at
    if read_attribute(:cycle_started_at).blank? || read_attribute(:cycle_started_at) < (resolved_cycle_at - 1.month)
      if @looping
      elsif subscription.nil? # silent plans
        update_attribute(:cycle_started_at, (resolved_cycle_at - 1.month))
      else
        self.reload # force subscription to reload
        puts "oh fuck, cycle_started_at no loaded <<<<<<<<<<"
        @looping = true
        update_attribute(:cycle_started_at, subscription.try(:current_period_started_at))
        @looping = false
      end
    end
    read_attribute(:cycle_started_at)
  end

  def resolved_cycle_at
    if read_attribute(:cycle_at).blank? || read_attribute(:cycle_at) <= Time.current
      if subscription.nil?
        if read_attribute(:cycle_at).blank?
          timeloop = created_at + 1.month
          while Time.now > timeloop
            timeloop += 1.month
          end
          update_attribute(:cycle_at, (timeloop + 1.month))
        else
          update_attribute(:cycle_at, (read_attribute(:cycle_at) + 1.month))
        end
      else
        self.reload # force subscription to reload
        puts "oh fuck, cycle_at no loaded <<<<<<<<<<"
        chargify_cycle_at = subscription.try(:current_period_ends_at)
        update_attribute(:cycle_at, chargify_cycle_at) unless chargify_cycle_at.nil?
      end
    end
    read_attribute(:cycle_at)
  end

  def max_messages
    read_attribute(:max_messages).to_i or 0
  end

  def messages_left
    @messages_left ||= begin # this is cached, but it should be per request, and would be reloaded on each request. This may be a pain for tests though
      total = self.max_messages
      used = Message.sum :recipients_count, :conditions => [ 'created_at >= ? and list_id in (?) and event_id is null', resolved_cycle_started_at, account.created_lists.collect{|l| l.id} ]

      # add extra messages
      unless credits.nil?
        total += credits.all(:conditions=>['expire_at >= ?', cycle_at]).sum {|credit| credit.messages}.to_i
      end

      total - used
    end
  end
  
  
  


  # a writter that only sets fields chargify needs
  def credit_card=(attributes)
    @credit_card = {
      :full_number => attributes['number'],
      :expiration_month => attributes['month'],
      :expiration_year => attributes['year'],
      :billing_zip => attributes['zip']
    }
  end



  def create_chargify
    if (Chargify::Subscription.find_by_customer_reference(self.account.id) rescue nil).nil?
      product_family = Chargify::ProductFamily.first
      components = Chargify::Component.all(:params => {:product_family_id => product_family.id})
      list_component_id = nil
      autoresponder_component_id = nil

      for component in components
        if component.unit_name == "list"
          list_component_id = component.id
        elsif component.unit_name == "autoresponder"
          autoresponder_component_id = component.id
        end
      end

      # create a chargify subscription
      attributes = {
        :product_handle => self.handle,
        :customer_reference => self.account_id,
        :customer_attributes => {
          :first_name => self.account.first_name,
          :last_name => self.account.last_name,
          :email => self.account.email,
          :reference => self.account.id
        },
        :coupon_code => self.try(:coupon_code),
        :credit_card_attributes => self.try(:credit_card)
      }
      attributes.delete(:customer_reference) if self.account.customer.nil?
      attributes.delete(:customer_attributes) if self.account.customer.present?
      attributes.delete(:credit_card_attributes) if self.credit_card.nil?

      attributes[:components] = []
      # since chargify doesn't allow changing subscription or product prices from the api
      # use a "cent" component that cost 1 cent per unit for custom plans
      if self.handle == 'custom'
        attributes[:components] << {
          :component_id => 2128, # umm, can't find a way to pull id automatically (1968)
          :allocated_quantity => self.price.cents
        }
      end

      attributes[:components] << {
          :component_id => list_component_id,
          :allocated_quantity => self.account.additional_lists
        }

      subscription = Chargify::Subscription.new(attributes)
      if subscription.save
        self.subscription_id = subscription.id
        self.cycle_started_at = subscription.current_period_started_at
        self.cycle_at = subscription.current_period_ends_at
        self.state = subscription.state
      else
        subscription.errors.full_messages.each{|err| self.errors[:base] << (err)}
        false
        raise ActiveRecord::Rollback
      end
    end
  end

  # todo: this needs to be after_create
  before_create :create_chargify

  def create_zendesk
    # create a zendesk account
    (Zendesk::User.load_account(plan.account).save rescue nil) if Rails.env.production?
  end
  after_create :create_zendesk

  # don't use this for upgrading/downgrading since it won't be prorated
  def update_chargify
    # only do this if price changed, it's slow and hardcoded... eww
    if self.handle == 'custom' and self.changes.include?("price")
      component = self.subscription.component(2128) # 1968
      # this will throw, should let it since we don't want to save if this fails
      component.allocated_quantity = self.price.cents
      component.save
    end

    if self.credit_card.present?
      if !self.subscription.nil?
        subscription = Chargify::Subscription.find_by_customer_reference(self.account_id)
        subscription.credit_card_attributes = self.credit_card
  
        if subscription.save
          if self.state == 'canceled'
            subscription.reactivate
          end
          self.cycle_started_at = subscription.current_period_started_at
          self.cycle_at = subscription.current_period_ends_at
          self.state = 'active'
        else
          subscription.errors.full_messages.each{|err| self.errors[:base] << err}
          false
          raise ActiveRecord::Rollback
        end
      else
        create_chargify
      end
    end
  end
  before_update :update_chargify

  def clear_chargify_stats
    if !self.changes.include?("cached_date")
      cached_last_payment = nil
      cached_signup_revenue = nil
      cached_date = nil
    end
  end
  before_save :clear_chargify_stats

  def resolved_signup_revenue
    check_update_chargify_stats

    return cached_last_payment
  end

  def resolved_last_payment
    check_update_chargify_stats

    return cached_last_payment
  end

  
  
  protected

    def check_update_chargify_stats
      if cached_date.nil? or cycle_at.nil? or cached_date < (cycle_at-30.days)
        sub = subscription
        last_payment = sub.transactions(:kinds => ["payment"]).first
        self.cached_last_payment = (last_payment and last_payment.amount_in_cents/100.0 or price.to_f)
        self.cached_signup_revenue = (sub and sub.signup_revenue or plan.price)
        self.cached_date = Time.now
        self.save
      end
    end

    def copy_plan_template
      PlanTemplate::TEMPLATED_ATTRIBUTES.each do |t|
        self.send(:"#{t}=", plan_template.send(t))
      end unless plan_template.nil?
    end

end
